
# Instructions

## Prerequisites

* Download and install vagrant

https://www.vagrantup.com/downloads.html

* Host NFS

http://askubuntu.com/questions/412525/vagrant-up-and-annoying-nfs-password-asking

```
As of version 1.7.3, the sudoers file in OS X should have these entries: 
Cmnd_Alias VAGRANT_EXPORTS_ADD = /usr/bin/tee -a /etc/exports
Cmnd_Alias VAGRANT_NFSD = /sbin/nfsd restart
Cmnd_Alias VAGRANT_EXPORTS_REMOVE = /usr/bin/sed -E -e /*/ d -ibak /etc/exports
%admin ALL=(root) NOPASSWD: VAGRANT_EXPORTS_ADD, VAGRANT_NFSD, VAGRANT_EXPORTS_REMOVE

And Linux will have these entries:


Cmnd_Alias VAGRANT_EXPORTS_ADD = /usr/bin/tee -a /etc/exports
Cmnd_Alias VAGRANT_NFSD_CHECK = /etc/init.d/nfs-kernel-server status
Cmnd_Alias VAGRANT_NFSD_START = /etc/init.d/nfs-kernel-server start
Cmnd_Alias VAGRANT_NFSD_APPLY = /usr/sbin/exportfs -ar
Cmnd_Alias VAGRANT_EXPORTS_REMOVE = /bin/sed -r -e * d -ibak /etc/exports
%sudo ALL=(root) NOPASSWD: VAGRANT_EXPORTS_ADD, VAGRANT_NFSD_CHECK, VAGRANT_NFSD_START, VAGRANT_NFSD_APPLY, VAGRANT_EXPORTS_REMOVE
``

* Install vagrant guest addon

```
vagrant plugin install vagrant-vbguest
```

* Download Fedora cloud image (libvirt, virtualbox) and install them

```
vagrant box add ../images/Fedora-Cloud-Base-Vagrant-23-20151030.x86_64.vagrant-libvirt.box --name=fedora23-libvirt
vagrant box add ../images/Fedora-Cloud-Base-Vagrant-23-20151030.x86_64.vagrant-virtualbox.box --name=fedora23-virtualbox
```

1) Root password

http://stackoverflow.com/questions/25758737/vagrant-login-as-root-by-default

sudo passwd -u root 

or

sudo echo 'vagrant ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

2) Install wget, git using dnf

dnf install wget
dnf install git

3) Download JDK

wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/8u73-b02/jdk-8u73-linux-x64.rpm

4) Install JDK

rpm -Uhv jdk-8u73-linux-x64.rpm

5) Setup JAVA_HOME

echo 'export JAVA_HOME=/usr/java/jdk1.8.0_73' >> /home/vagrant/.bash_profile
echo 'export PATH=$PATH:${JAVA_HOME}/bin' >> /home/vagrant/.bash_profile

6) Download & install maven 3.2.3

cd /usr/local
wget http://archive.apache.org/dist/maven/maven-3/3.2.3/binaries/apache-maven-3.2.3-bin.tar.gz
tar -vxf apache-maven-3.2.3-bin.tar.gz
rm -f apache-maven-3.2.3-bin.tar.gz

7) Set env var

echo 'export M2_HOME=/usr/local/apache-maven-3.2.3' >> /home/vagrant/.bash_profile
echo 'export M2=$M2_HOME/bin' >> /home/vagrant/.bash_profile
echo 'export PATH=$M2:$PATH' >> /home/vagrant/.bash_profile

8) Sync Folders

config.vm.synced_folder "src/", "/srv/website"

9) Download and test JBoss Fuse 6.2.1 (can we do that in silent mode)

wget --no-cookies --no-check-certificate https://developers.redhat.com/download-manager/file/jboss-fuse-6.2.1.GA-full_zip.zip

https://repository.jboss.org/nexus/content/groups/ea/org/jboss/fuse/jboss-fuse-full/6.2.1.redhat-090/jboss-fuse-full-6.2.1.redhat-090.zip

wget https://access.cdn.redhat.com/content/origin/files/sha256/e5/e5bdb31df14dd8bb17886a7a4232e3fbce0cce86b5e6ddfbb3d3f84e244fd9ff/jboss-fuse-full-6.2.1.redhat-084.zip?_auth_=1455615351_3f253dfec14d37e10c47b7dc21f41fec

## Fedora

* Add an adapter for the vboxnet0 interface

Add a config for the vboxnet0 host adapter. The HWADDR correponds to the MAC address asignedthat you can see within the settings of Virtualbox.

more /etc/sysconfig/network-scripts/ifcfg-vboxnet0
DEVICE="vboxnet0"
HWADDR="0A:00:27:00:00:00"
BOOTPROTO="static"
IPADDR=172.28.128.4
NETMASK=255.255.255.0
GATEWAY=172.28.128.1
ONBOOT="yes"

* Start vboxnet0 adpater 

sudo ifdown vboxnet0 && sudo ifup vboxnet0

## Virtualbox

* Start

VBoxManage startvm "dev-fuse-vm" --type headless

* Check status

VBoxManage showvminfo "dev-fuse-vm"

* List vms

VBoxManage list vms





