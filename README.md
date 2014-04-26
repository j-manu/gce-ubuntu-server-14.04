gce-ubuntu-server-14.04
=======================

Ubuntu Server 14.04 LTS Image Generator for Google Compute Engine

# Quickstart

In order to build a virtual machine, you'll need [Vagrant](http://vagrantup.com/) and a matching VM provider. **Using the 'virtualbox' provider will not work**, therefore OS X users can only build an image using the commercial 'vmware_fusion' provider. It should work with other providers that offer nested virtualization, too, but we didn't test that.


```
client$ vagrant up --provider=vmware_fusion
client$ vagrant ssh
[wait for the process to finish]
client$ vagrant destroy
client$ gsutil cp output_1404/ubuntu-14.04-image.tar.gz gs://<your-bucket>
client$ gcutil --project=<your-project> addimage ubuntu-14-04 gs://<your-bucket>/ubuntu-14.04-image.tar.gz
```
