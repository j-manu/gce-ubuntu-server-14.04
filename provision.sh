#!/bin/bash

echo "Starting sudo"
echo |sudo -S bash <<'EOF'
  "Th3reIsNoSp00n!"
  echo "Running provisioner"
  apt-get update && apt-get upgrade -yq
  rm -rf /etc/hostname
  echo -e "127.0.0.1 localhost\n169.254.169.254 metadata.google.internal metadata" > /etc/hosts
  apt-get install openssh-server python2.7 -yq
  wget https://github.com/GoogleCloudPlatform/compute-image-packages/releases/download/1.1.2/google-startup-scripts_1.1.2-1_all.deb
  dpkg -i google-startup-scripts_1.1.2-1_all.deb
  apt-get install -f -yq
  wget https://github.com/GoogleCloudPlatform/compute-image-packages/releases/download/1.1.2/python-gcimagebundle_1.1.2-1_all.deb
  dpkg -i python-gcimagebundle_1.1.2-1_all.deb
  apt-get install -f -yq
  wget https://github.com/GoogleCloudPlatform/compute-image-packages/releases/download/1.1.2/google-compute-daemon_1.1.2-1_all.deb
  dpkg -i python-gcimagebundle_1.1.2-1_all.deb
  apt-get install -f -yq

  rm -rf /etc/ssh/ssh_host_key
  rm -rf /etc/ssh/ssh_host_rsa_key*
  rm -rf /etc/ssh/ssh_host_dsa_key*
  rm -rf /etc/ssh/ssh_host_ecdsa_key*
  usermod -L root
  echo 1 > /proc/sys/kernel/modules_disabled
EOF
