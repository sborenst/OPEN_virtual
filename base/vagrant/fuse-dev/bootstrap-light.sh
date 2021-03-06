#!/usr/bin/env bash

set -x

# Local variables
VM_MEMORY=$1
MAVEN_VERSION=$2
FUSE_VERSION=$3
GIT_REPO_URL=$4
GIT_REPO_NAME=$5

# Check memory
echo "=========================================================================="
echo "Using VM Memory of ${VM_MEMORY} MB"
if [ ${VM_MEMORY} -lt 3000 ]; then
  echo "NOTE: We recommend at least 3000 MB for running with JBoss Fuse and Fabric Containers."
  echo "      You can specify this with an environment variable FUSE_VM_MEMORY"
  echo "      E.g. when creating the VM with : 'FUSE_VM_MEMORY=3000 vagrant up'"
fi
echo "=========================================================================="


# Install Git, 
echo 'Install git, wget, unzip'
sudo dnf -y install wget git unzip nfs-utils firewalld

# Configure firewall to allow to use nfs

systemctl status firewalld

sudo firewall-cmd --permanent --add-service=nfs &&
sudo firewall-cmd --permanent --add-service=rpc-bind &&
sudo firewall-cmd --permanent --add-service=mountd &&
sudo firewall-cmd --permanent --add-port=8100-9999/tcp &&
sudo firewall-cmd --reload

# Create Tmp dir
# echo "Create Temp Directory under vagrant home"
# mkdir -p $vagrant_home_dir/tmp

# Download and install JDK
echo "Download and install JDK8"

pushd $vagrant_home_dir/tmp
wget --quiet --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/8u73-b02/jdk-8u73-linux-x64.rpm
rpm -Uhv jdk-8u73-linux-x64.rpm
popd

# Download & install Apache Maven ${MAVEN_VERSION}
echo "Download & install Apache Maven ${MAVEN_VERSION}"
pushd /usr/local
wget --quiet  http://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz
tar -vxf apache-maven-${MAVEN_VERSION}-bin.tar.gz
sudo rm -f apache-maven-${MAVEN_VERSION}-bin.tar.gz
popd

# Set env Variables for Maven, JDK & export them
echo "Set env Variables for Maven, JDK & export them"
su -c 'cat <<EOF >> /home/vagrant/.bash_profile
# Java Home
export JAVA_HOME=/usr/java/jdk1.8.0_73
export PATH=\$PATH:\$JAVA_HOME/bin
# Maven Home
export M2_HOME=/usr/local/apache-maven-'"${MAVEN_VERSION}"'
export PATH=\$PATH:\$M2_HOME/bin
EOF' vagrant
