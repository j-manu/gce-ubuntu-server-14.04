# -*- mode: ruby -*-
# vi: set ft=ruby :

$script = <<SCRIPT
echo I am provisioning...
apt-get update && apt-get -qy upgrade
apt-get install -qy qemu-kvm unzip
modprobe kvm-intel
mkdir -p packer && pushd packer
  wget -q https://dl.bintray.com/mitchellh/packer/0.5.2_linux_amd64.zip
  unzip 0.5.2_linux_amd64.zip
popd
date > /etc/vagrant_provisioned_at
cat >/usr/bin/gcx_build_vm <<GCXBUILDVM
#!/bin/bash

cd /vagrant
echo 'Downloading ubuntu-14.04-server-amd64.iso...'
wget -c http://releases.ubuntu.com/14.04/ubuntu-14.04-server-amd64.iso -O ubuntu-14.04-server-amd64.iso
echo
echo
echo 'Done. Now building VM...'
sleep 2
rm -rf /vagrant/output_*
/home/vagrant/packer/packer build vm.json
echo
echo
echo 'Done building VM using packer. Building image archive...'
cd /vagrant/output_*
mv *.raw disk.raw
tar -zcf ubuntu-14.04-image.tar.gz disk.raw
echo
echo 'Done! You are now leaving vagrant to upload your new Ubuntu image using gsutil.'
echo '* OPTIONAL: create a new bucket: gsutil mb gs://<bucket-name>'
echo '* gsutil cp output_*/ubuntu-14.04-image.tar.gz gs://<bucket-name>'
echo '* gcutil --project=<your-project> addimage ubuntu-14-04 gs://<bucket-name>/ubuntu-14.04-image.tar.gz'
echo
echo 'Do not forget to clean up vagrant leftovers using "vagrant destroy".'
sleep 3
poweroff
GCXBUILDVM
chmod +x /usr/bin/gcx_build_vm
echo "sudo /usr/bin/gcx_build_vm" >>/home/vagrant/.bashrc
rm /etc/update-motd.d/00-header
rm /etc/update-motd.d/10-help-text
rm /etc/update-motd.d/91-release-upgrade
echo -e '#!/bin/sh\n\ncat /etc/motd' >/etc/update-motd.d/99-grandcentrix
cat >/etc/motd <<MOTD
[1;32;40m                                .___[1;33;40m                   __         .__        [0m
[1;32;40m   ________________    ____   __| _/[1;33;40m[1;33;40m____  ____   _____/  |________|_____  ___[0m
[1;32;40m  / ___\\_  __ \\__  \\  /    \\ / __ _/[1;33;40m[1;33;40m ____/ __ \\ /    \\   __\\_  __ |  \\  \\/  /[0m
[1;32;40m / /_/  |  | \\// __ \\|   |  / /_/ [1;33;40m[1;33;40m\\  \\__\\  ___/|   |  |  |  |  | \\|  |>    < [0m
[1;32;40m \\___  /|__|  (____  |___|  \\____ |[1;33;40m[1;33;40m\\___  \\___  |___|  |__|  |__|  |__/__/\\_ \\[0m
[1;32;40m/_____/            \\/     \\/     \\/[1;33;40m[1;33;40m    \\/    \\/     \\/   [0mgrandcentrix.net  [1;33;40m\\/[0m
                                                         GCE image builder

MOTD
chmod +x /etc/update-motd.d/99-grandcentrix
/etc/update-motd.d/99-grandcentrix >/var/run/motd
echo
echo
echo 'Done. Continue with "vagrant ssh".'
SCRIPT

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

ENV['VAGRANT_DEFAULT_PROVIDER'] = 'vmware_fusion'

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "chef/ubuntu-14.04"
  config.vm.provider "vmware_fusion" do |v|
    v.vmx["memsize"] = "4096"
    v.vmx["numvcpus"] = "2"
    v.vmx["vhv.enable"] = "TRUE" # Enable nested virtualization for qemu-kvm
  end
  config.vm.provision "shell", inline: $script
end
