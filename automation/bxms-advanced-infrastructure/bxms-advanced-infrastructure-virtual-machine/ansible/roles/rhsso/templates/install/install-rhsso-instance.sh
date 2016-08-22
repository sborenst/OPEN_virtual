#!/bin/bash

SCRIPT_DIR=$(cd -P -- "$(dirname -- "$0")" && pwd -P)

IP_ADDR=127.0.0.1
RESOURCES_DIR=$SCRIPT_DIR/resources
CONFIGURATION_DIR=$SCRIPT_DIR/configuration
RHSSO_DISTRO={{rhsso_distro}}
RHSSO=$RESOURCES_DIR/$RHSSO_DISTRO
RHSSO_HOME=${RHSSO_HOME:-/home/jboss/lab}
RHSSO_ROOT=${RHSSO_ROOT:-rhsso}
RHSSO_ROOT_ORIG={{rhsso_root_orig}}
MYSQL_DRIVER={{rhsso_mysql_driver}}
FORCE=false

# MySql schema
MYSQL_RHSSO_SCHEMA=${MYSQL_RHSSO_SCHEMA:-rhsso}

# Sanity Checks
if [ -f $RHSSO ];
then
    echo "File $RHSSO found"
else
    echo "File $RHSSO not found. Please put it in the resources folder"
    exit 255
fi

if [ -f $MYSQL_DRIVER ];
then
    echo "$MYSQL_DRIVER installed"
else
    echo "File $MYSQL_DRIVER not installed. Please install with yum"
    exit 255
fi

if [ -d $RHSSO_HOME/$RHSSO_ROOT ];
then
  if [ "$FORCE" = "true" ] ;
    then
      echo "Removing existing installation"
      rm -rf $RHSSO_HOME/$RHSSO_ROOT
    else  
      echo "Target directory already exists. Please remove it before installing RH-SSO again."
      exit 250
  fi 
fi

# Install rhsso
echo "Unzipping RH-SSO"
unzip -q $RHSSO -d $RHSSO_HOME

echo "Renaming the RHSSO dir to $RHSSO_ROOT"
mv $RHSSO_HOME/$RHSSO_ROOT_ORIG $RHSSO_HOME/$RHSSO_ROOT

# Copy `keycloak-add-user.json`
echo "Copy keycloak-add-user.json to $RHSSO_HOME/$RHSSO_ROOT/standalone/configuration"
cp $CONFIGURATION_DIR/keycloak-add-user.json $RHSSO_HOME/$RHSSO_ROOT/standalone/configuration/

# Configure persistence
$RHSSO_HOME/$RHSSO_ROOT/bin/jboss-cli.sh --file=$CONFIGURATION_DIR/rhsso.cli

# Configure mysql
mysql -u root < $CONFIGURATION_DIR/rhsso-mysql.sql

# Set system properties
# Server settings
echo "Set system properties"
echo $'\n' >> $RHSSO_HOME/$RHSSO_ROOT/bin/standalone.conf
echo "JAVA_OPTS=\"\$JAVA_OPTS -Djboss.bind.address=0.0.0.0\"" >> $RHSSO_HOME/$RHSSO_ROOT/bin/standalone.conf
echo "JAVA_OPTS=\"\$JAVA_OPTS -Djboss.bind.address.management=0.0.0.0\"" >> $RHSSO_HOME/$RHSSO_ROOT/bin/standalone.conf
echo "JAVA_OPTS=\"\$JAVA_OPTS -Djboss.node.name=server-$IP_ADDR\"" >> $RHSSO_HOME/$RHSSO_ROOT/bin/standalone.conf

if [ "x$JBOSS_PORT_OFFSET" != "x" ]
then
  echo "JAVA_OPTS=\"\$JAVA_OPTS -Djboss.socket.binding.port-offset=$JBOSS_PORT_OFFSET\"" >> $RHSSO_HOME/$RHSSO_ROOT/bin/standalone.conf
fi

# mysql
echo "JAVA_OPTS=\"\$JAVA_OPTS -Dmysql.host.ip=$IP_ADDR\"" >> $RHSSO_HOME/$RHSSO_ROOT/bin/standalone.conf
echo "JAVA_OPTS=\"\$JAVA_OPTS -Dmysql.host.port=3306\"" >> $RHSSO_HOME/$RHSSO_ROOT/bin/standalone.conf
echo "JAVA_OPTS=\"\$JAVA_OPTS -Dmysql.rhsso.schema=$MYSQL_RHSSO_SCHEMA\"" >> $RHSSO_HOME/$RHSSO_ROOT/bin/standalone.conf
