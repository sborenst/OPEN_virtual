#!/bin/bash

SCRIPT_DIR=$(cd -P -- "$(dirname -- "$0")" && pwd -P)

HOME_DIR=/home/jboss
LAB_DIR=$HOME_DIR/lab
RESOURCES_DIR=$SCRIPT_DIR/resources
CONFIGURATION_DIR=$SCRIPT_DIR/configuration
MVN_DISTRO=apache-maven-3.2.5-bin.zip
MVN=$RESOURCES_DIR/$MVN_DISTRO
MVN_ROOT_DIR=apache-maven-3.2.5
MVN_INSTALL_DIR=$LAB_DIR/mvn
MVN_SETTINGS=$CONFIGURATION_DIR/mvn-settings.xml


#
# Check prerequisites
#
function check_prerequisites {

  if [ ! -f $MVN ] 
  then
    echo "File $MVN not found. Please put it in the $RESOURCES_DIR folder."
    exit 250
  else 
    echo "File $MVN found." 
  fi

}

#
# Install Maven
#
function install_mvn {

  echo "Installing Maven in ${MVN_INSTALL_DIR}"
  unzip $MVN -d $MVN_INSTALL_DIR
  if [ ! -d $HOME_DIR/.m2 ]
    then 
      mkdir $HOME_DIR/.m2  
  fi
  cp -f $MVN_SETTINGS $HOME_DIR/.m2/settings.xml
  
  RET=`cat $HOME_DIR/.bashrc | grep "M2_HOME=" | grep -v "#"`
  if [[ "$RET" == "" ]]
    then
      echo $'\n' >> $HOME_DIR/.bashrc
      echo "export M2_HOME=$MVN_INSTALL_DIR/$MVN_ROOT_DIR" >> $HOME_DIR/.bashrc
      echo "export PATH=\$M2_HOME/bin:\$PATH" >> $HOME_DIR/.bashrc
  fi

}

check_prerequisites
install_mvn

echo "Change owner to user jboss"
chmod 755 $MVN_INSTALL_DIR/$MVN_ROOT_DIR/bin/mvn
chown -R jboss:jboss $MVN_INSTALL_DIR
chown -R jboss:jboss $HOME_DIR/.m2

exit 0





