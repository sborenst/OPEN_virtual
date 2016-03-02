#!/usr/bin/env bash

set -x

# Local variables
VM_MEMORY=$1
MAVEN_VERSION=$2
JAVA_PACKAGE=$3
JAVA_VERSION=$4

# Check memory
echo "=========================================================================="
echo "Using VM Memory of ${VM_MEMORY} MB"
if [ ${VM_MEMORY} -lt 3000 ]; then
  echo "NOTE: We recommend at least 3000 MB for running with JBoss Fuse and Fabric Containers."
  echo "      You can specify this with an environment variable FUSE_VM_MEMORY"
  echo "      E.g. when creating the VM with : 'FUSE_VM_MEMORY=3000 vagrant up'"
fi
echo "=========================================================================="

# Install Git, Wget, Unzip Tools
echo 'Install git, wget, unzip'
sudo yum -y install wget git unzip nfs-utils bind-utils

# Install Open JDK 8 (Dev)
echo "Download and install OpenJDK 8"

sudo yum -y install ${JAVA_PACKAGE}

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
export JAVA_HOME=/usr/lib/jvm/'"${JAVA_VERSION}"'
export PATH=\$PATH:\$JAVA_HOME/bin

# Maven Home
export M2_HOME=/usr/local/apache-maven-'"${MAVEN_VERSION}"'
export PATH=\$PATH:\$M2_HOME/bin
EOF' vagrant
