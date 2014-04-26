#!/bin/bash

# Nice reference: https://developers.google.com/compute/docs/images#buildingimage
# Would be even nicer if Google would use it in their own debian images.

echo "Running provisioner"

# Update APT cache, upgrade packages
apt-get update && apt-get -yq dist-upgrade

# Removing hostname, adding internal hosts
rm /etc/hostname
echo -e "127.0.0.1 localhost\n169.254.169.254 metadata.google.internal metadata" > /etc/hosts

# Setting up ntp
sed -i -e "/server/d" /etc/ntp.conf
echo "server 169.254.169.254" >>/etc/ntp.conf

# Install mandatory software
apt-get install -yq openssh-server python2.7 python2.7-dev python-pip vim htop unzip fail2ban curl ethtool kpartx

# Install GCE specific software
wget -q https://github.com/GoogleCloudPlatform/compute-image-packages/releases/download/1.1.2/google-startup-scripts_1.1.2-1_all.deb
dpkg -i google-startup-scripts_1.1.2-1_all.deb
apt-get install -f -yq
wget -q https://github.com/GoogleCloudPlatform/compute-image-packages/releases/download/1.1.2/python-gcimagebundle_1.1.2-1_all.deb
dpkg -i python-gcimagebundle_1.1.2-1_all.deb
apt-get install -f -yq
wget -q https://github.com/GoogleCloudPlatform/compute-image-packages/releases/download/1.1.2/google-compute-daemon_1.1.2-1_all.deb
dpkg -i google-compute-daemon_1.1.2-1_all.deb
apt-get install -f -yq

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
cat >/etc/sysctl.conf <<EOF
# Disable IPv6 as it is still unsupported on GCE, even though it's 2014 already
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1

# Google-recommended kernel parameters

# Turn on SYN-flood protections.  Starting with 2.6.26, there is no loss
# of TCP functionality/features under normal conditions.  When flood
# protections kick in under high unanswered-SYN load, the system
# should remain more stable, with a trade off of some loss of TCP
# functionality/features (e.g. TCP Window scaling).
net.ipv4.tcp_syncookies=1

# Ignore source-routed packets
net.ipv4.conf.all.accept_source_route=0
net.ipv4.conf.default.accept_source_route=0

# Ignore ICMP redirects from non-GW hosts
net.ipv4.conf.all.accept_redirects=0
net.ipv4.conf.default.accept_redirects=0
net.ipv4.conf.all.secure_redirects=1
net.ipv4.conf.default.secure_redirects=1

# Don't pass traffic between networks or act as a router
net.ipv4.ip_forward=0
net.ipv4.conf.all.send_redirects=0
net.ipv4.conf.default.send_redirects=0

# Turn on Source Address Verification in all interfaces to
# prevent some spoofing attacks.
net.ipv4.conf.all.rp_filter=1
net.ipv4.conf.default.rp_filter=1

# Ignore ICMP broadcasts to avoid participating in Smurf attacks
net.ipv4.icmp_echo_ignore_broadcasts=1

# Ignore bad ICMP errors
net.ipv4.icmp_ignore_bogus_error_responses=1

# Log spoofed, source-routed, and redirect packets
net.ipv4.conf.all.log_martians=1
net.ipv4.conf.default.log_martians=1

# RFC 1337 fix
net.ipv4.tcp_rfc1337=1

# Addresses of mmap base, heap, stack and VDSO page are randomized
kernel.randomize_va_space=2

# Reboot the machine soon after a kernel panic.
kernel.panic=10
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

# Upstart scripts
cat >>/etc/init/gcx-set-hostname.conf <<EOF
start on (starting ssh or starting sshd)

# this is a task, so only run once
task

script
  # set hostname to the one returned by the google metadata server
  hostname \`/usr/share/google/get_metadata_value hostname\`
end script
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
