gce-ubuntu-server-14.04
=======================

Ubuntu Server 14.04 LTS Image Generator for Google Compute Engine

# Quickstart

If you just want to try it, you may use our precompiled image:

```
gcutil addimage ubuntu-14-04 gs://gcx-devops-images/ubuntu-14.04-image.tar.gz
```

Please be aware that you are essentially running an OS image that you cannot possibly audit. **Do not use this image in production.** We urge you to **build your own image** (using the instructions below). The process is very streamlined and will only take about 30-60 minutes, depending on machine and network speed.

# Build your own

In order to build a virtual machine, you'll need [Vagrant](http://vagrantup.com/) and a matching VM provider. **Using the 'virtualbox' provider will not work**, therefore OS X users can only build an image using the commercial 'vmware_fusion' provider. It should work with other providers that offer nested virtualization, too, but we didn't test that.

```
client$ vagrant up --provider=vmware_fusion
client$ vagrant ssh
[wait for the process to finish]
client$ vagrant destroy
client$ gsutil cp output_1404/ubuntu-14.04-image.tar.gz gs://<your-bucket>
client$ gcutil --project=<your-project> addimage ubuntu-14-04 gs://<your-bucket>/ubuntu-14.04-image.tar.gz
```
