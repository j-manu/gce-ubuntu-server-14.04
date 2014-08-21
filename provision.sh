#!/bin/bash

# Nice reference: https://developers.google.com/compute/docs/images#buildingimage
# Would be even nicer if Google would use it in their own debian images.

echo "Running provisioner"

GCE_IMAGE_VERSION=1.1.6

# Update APT cache, upgrade packages
apt-get update && apt-get -yq dist-upgrade

# Set up UTC timezone
ln -sf /usr/share/zoneinfo/UTC /etc/localtime

# Setting up ntp
sed -i -e "/server/d" /etc/ntp.conf
echo "server 169.254.169.254" >>/etc/ntp.conf

# Install mandatory software
apt-get install -yq openssh-server python2.7 python2.7-dev python-pip vim htop unzip fail2ban curl ethtool kpartx

# Install GCE specific software
for pkg in google-startup-scripts python-gcimagebundle google-compute-daemon
do
  wget -q "https://github.com/GoogleCloudPlatform/compute-image-packages/releases/download/${GCE_IMAGE_VERSION}/${pkg}_${GCE_IMAGE_VERSION}-1_all.deb" -O ${pkg}-${GCE_IMAGE_VERSION}.deb
  dpkg -i ${pkg}-${GCE_IMAGE_VERSION}.deb
done
apt-get -f -yq install

# Removing hostname, adding internal hosts
rm /etc/hostname
echo -e "127.0.0.1 localhost\n169.254.169.254 metadata.google.internal metadata" > /etc/hosts
ln -s /usr/share/google/set-hostname /etc/dhcp/dhclient-exit-hooks.d/

# Remove sshd host keys
rm -f /etc/ssh/ssh_host_key
rm -f /etc/ssh/ssh_host_*_key*

# Reconfigure sshd
sed -i -e "s/PermitRootLogin without-password/PermitRootLogin no/" /etc/ssh/sshd_config
sed -i -e "s/#PasswordAuthentication yes/PasswordAuthentication no/" /etc/ssh/sshd_config
sed -i -e "s/X11Forwarding yes/X11Forwarding no" /etc/ssh/sshd_config

echo "PermitTunnel no" >>/etc/ssh/sshd_config
echo "AllowTcpForwarding yes" >>/etc/ssh/sshd_config
echo "ClientAliveInterval 420" >>/etc/ssh/sshd_config
echo "UseDNS no" >>/etc/ssh/sshd_config

# Creating /etc/ssh/sshd_not_to_be_run will disable starting of sshd by default.
# Google startup scripts will check for this value (GOOGLE)  and start sshd
# after creating new host keys
echo "GOOGLE" >/etc/ssh/sshd_not_to_be_run

cat >/etc/ssh/ssh_config <<EOF
Host *
Protocol 2
ForwardAgent no
ForwardX11 no
HostbasedAuthentication no
StrictHostKeyChecking no
Ciphers aes128-ctr,aes192-ctr,aes256-ctr,arcfour256,arcfour128,aes128-cbc,3des-cbc
Tunnel no

# Google Compute Engine times out connections after 10 minutes of inactivity.
# Keep alive ssh connections by sending a packet every 7 minutes.
ServerAliveInterval 420
EOF

# Lock root user
usermod -L root

# Disable CAP_SYS_MODULE
echo 1 > /proc/sys/kernel/modules_disabled

# Remove System.map
rm /boot/System.map*

# Fix sysctl values
cat >/etc/sysctl.d/49-disable-ipv6.conf <<EOF
# Disable IPv6 as it is still unsupported on GCE, even though it's 2014 already
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
EOF

cat >/etc/sysctl.d/50-gce-recommended.conf <<EOF
# provides protection from ToCToU races
fs.protected_hardlinks=1

# provides protection from ToCToU races
fs.protected_symlinks=1

# makes locating kernel addresses more difficult
kernel.kptr_restrict=1

# set ptrace protections
kernel.yama.ptrace_scope=1

# set perf only available to root
kernel.perf_event_paranoid=2
EOF

# Install gcloud utilities
mkdir -p /opt/google
pushd /opt/google
wget https://dl.google.com/dl/cloudsdk/release/google-cloud-sdk.zip
unzip google-cloud-sdk.zip
pushd google-cloud-sdk
CLOUDSDK_CORE_DISABLE_PROMPTS=1 ./install.sh --disable-installation-options --path-update=true --bash-completion=true --rc-path=/etc/bash.bashrc
popd
popd

# Log syslog messages to /dev/ttyS0
cat >/etc/default/grub <<EOF
RUB_DEFAULT=0
GRUB_TIMEOUT=0
GRUB_HIDDEN_TIMEOUT=0
GRUB_HIDDEN_TIMEOUT_QUIET=true
GRUB_DISTRIBUTOR=`lsb_release -i -s 2> /dev/null || echo Debian`
GRUB_CMDLINE_LINUX_DEFAULT="console=ttyS0"
GRUB_CMDLINE_LINUX="console=ttyS0,115200n8 ignore_loglevel"
GRUB_TERMINAL=console
EOF
update-grub

# Upstart scripts
cat >/etc/init/ttyS0.conf <<EOF
# ttyS0 - getty
start on stopped rc or RUNLEVEL=[2345]
stop on runlevel [!2345]
respawn
exec /sbin/getty -L 115200 ttyS0 vt102
EOF

cat >>/etc/init/gcx-remove-bootstrap.conf <<EOF
start on (starting ssh or starting sshd)

# this is a task, so only run once
task

script
  # delete bootstrap user
  userdel -f -r bootstrap
  rm /etc/init/gcx-remove-bootstrap.conf
end script
EOF
initctl reload-configuration
