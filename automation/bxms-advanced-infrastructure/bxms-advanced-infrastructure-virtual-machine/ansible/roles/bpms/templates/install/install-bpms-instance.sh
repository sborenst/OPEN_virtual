#!/bin/bash

SCRIPT_DIR=$(cd -P -- "$(dirname -- "$0")" && pwd -P)

IP_ADDR=127.0.0.1
RESOURCES_DIR=$SCRIPT_DIR/resources
EAP_DISTRO={{eap_distro}}
EAP=$RESOURCES_DIR/$EAP_DISTRO
BPMS_DISTRO={{bpms_distro}}
BPMS=$RESOURCES_DIR/$BPMS_DISTRO
BPMS_HOME=${BPMS_HOME:-/home/jboss/lab}
BPMS_ROOT=${BPMS_ROOT:-bpms}
BPMS_ROOT_ORIG={{bpms_root_orig}}
BPMS_DATA_DIR=$BPMS_HOME/$BPMS_ROOT/data
REPO_DIR=bpms-repo
MYSQL_DRIVER={{bpms_mysql_driver}}

# Defaults
DASHBOARD=${DASHBOARD:-true}
KIE_SERVER=${KIE_SERVER:-true}
BUSINESS_CENTRAL=${BUSINESS_CENTRAL:-true}

# Kie-server
BPMS_EXT_DISABLED=${BPMS_EXT_DISABLED:-false}
BRMS_EXT_DISABLED=${BRMS_EXT_DISABLED:-false}
BRP_EXT_DISABLED=${BRP_EXT_DISABLED:-true}
JBPMUI_EXT_DISABLED=${JBPMUI_EXT_DISABLED:-false}
KIE_SERVER_BYPASS_AUTH_USER=${KIE_SERVER_BYPASS_AUTH_USER:-false}

# Managed Kie-server
KIE_SERVER_CONTROLLER=${KIE_SERVER_CONTROLLER:-false}
KIE_SERVER_MANAGED=${KIE_SERVER_MANAGED:-false}

# MySql schema
MYSQL_BPMS_SCHEMA=${MYSQL_BPMS_SCHEMA:-bpms}

echo "BUSINESS_CENTRAL=$BUSINESS_CENTRAL"
echo "KIE_SERVER=$KIE_SERVER"
echo "DASHBOARD=$DASHBOARD"

# Helper function for creating users
function createUser() {
  user=$1
  password=$2
  realm=management
  if [ ! -z $3 ]
  then
    roles=$3
    realm=application
  fi

  if [ "$realm" == "management" ]
  then
    $BPMS_HOME/$BPMS_ROOT/bin/add-user.sh -u $user -p $password -s -sc $BPMS_HOME/$BPMS_ROOT/standalone/configuration
  else
    $BPMS_HOME/$BPMS_ROOT/bin/add-user.sh -u $user -p $password -g $roles -a -s -sc $BPMS_HOME/$BPMS_ROOT/standalone/configuration
  fi
}

# Sanity Checks
if [ -f $EAP ];
then
    echo "File $EAP found"
else
    echo "File $EAP not found. Please put it in the resources folder"
    exit 255
fi

if [ -f $BPMS ];
then
    echo "File $BPMS found"
else
    echo "File $BPMS not found. Please put it in the resources folder"
    exit 255
fi

if [ -f $MYSQL_DRIVER ];
then
    echo "$MYSQL_DRIVER installed"
else
    echo "File $MYSQL_DRIVER not installed. Please install with yum"
    exit 255
fi

if [ -d $BPMS_HOME/$BPMS_ROOT ];
then
  if [ "$FORCE" = "true" ] ;
    then
      echo "Removing existing installation"
      rm -rf $BPMS_HOME/$BPMS_ROOT
    else  
      echo "Target directory already exists. Please remove it before installing BPMS again."
      exit 250
  fi 
fi

# Install bpms
echo "Unzipping EAP"
unzip -q $EAP -d $BPMS_HOME

echo "Unzipping BPMS"
unzip -q -o $BPMS -d $BPMS_HOME

echo "Renaming the EAP dir to $BPMS_ROOT"
mv $BPMS_HOME/$BPMS_ROOT_ORIG $BPMS_HOME/$BPMS_ROOT

# Remove unwanted deployments
if [ ! "$DASHBOARD" = "true" ];
then
  rm -f $BPMS_HOME/$BPMS_ROOT/standalone/deployments/dashbuilder.war.*
else
  rm -f $BPMS_HOME/$BPMS_ROOT/standalone/deployments/dashbuilder.war.*
  touch $BPMS_HOME/$BPMS_ROOT/standalone/deployments/dashbuilder.war.dodeploy
fi

if [ ! "$BUSINESS_CENTRAL" = "true" ];
then
  rm -f $BPMS_HOME/$BPMS_ROOT/standalone/deployments/business-central.war.*
else
  rm -f $BPMS_HOME/$BPMS_ROOT/standalone/deployments/business-central.war.*
  touch $BPMS_HOME/$BPMS_ROOT/standalone/deployments/business-central.war.dodeploy
fi

if [ ! "$KIE_SERVER" = "true" ];
then
  rm -f $BPMS_HOME/$BPMS_ROOT/standalone/deployments/kie-server.war.*
else
  rm -f $BPMS_HOME/$BPMS_ROOT/standalone/deployments/kie-server.war.*
  touch $BPMS_HOME/$BPMS_ROOT/standalone/deployments/kie-server.war.dodeploy
fi

# Kie server has no quartz library
if [ ! -f  $BPMS_HOME/$BPMS_ROOT/standalone/deployments/kie-server.war/WEB-INF/lib/quartz-1.8.5.jar ];
then 
   echo "Copying quartz library to kie-server deployment"
   cp $BPMS_HOME/$BPMS_ROOT/standalone/deployments/business-central.war/WEB-INF/lib/quartz-1.8.5.jar \
   $BPMS_HOME/$BPMS_ROOT/standalone/deployments/kie-server.war/WEB-INF/lib
fi

# Remove org.kie.example
echo "Remove org.kie.example"
sed -i 's/property name="org.kie.example" value="true"/property name="org.kie.example" value="false"/' $BPMS_HOME/$BPMS_ROOT/standalone/configuration/standalone.xml

# Relax restrictions on user passwords
sed -i "s/password.restriction=REJECT/password.restriction=RELAX/" $BPMS_HOME/$BPMS_ROOT/bin/add-user.properties

# Create application user jboss:bpms
echo "Create application user jboss:bpms"
createUser "jboss" "bpms" "admin,analyst,user,kie-server,rest-all"

# Create management user admin:admin
echo "Create management user admin:admin"
createUser "admin" "admin"

# Userinfo properties
touch $BPMS_HOME/$BPMS_ROOT/standalone/configuration/bpms-userinfo.properties

# Create directories and set permissions
echo "Make directories for maven and git repo"
mkdir -p $BPMS_DATA_DIR/$REPO_DIR

# Set system properties
# Server settings
echo "Set system properties"
echo $'\n' >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
echo "JAVA_OPTS=\"\$JAVA_OPTS -Djboss.bind.address=0.0.0.0\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
echo "JAVA_OPTS=\"\$JAVA_OPTS -Djboss.bind.address.management=0.0.0.0\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
echo "JAVA_OPTS=\"\$JAVA_OPTS -Djboss.bind.address.insecure=0.0.0.0\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
echo "JAVA_OPTS=\"\$JAVA_OPTS -Djboss.node.name=server-$IP_ADDR\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf

if [ "x$JBOSS_PORT_OFFSET" != "x" ]
then
  echo "JAVA_OPTS=\"\$JAVA_OPTS -Djboss.socket.binding.port-offset=$JBOSS_PORT_OFFSET\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
fi

# mysql
echo "JAVA_OPTS=\"\$JAVA_OPTS -Dmysql.host.ip=$IP_ADDR\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
echo "JAVA_OPTS=\"\$JAVA_OPTS -Dmysql.host.port=3306\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
echo "JAVA_OPTS=\"\$JAVA_OPTS -Dmysql.bpms.schema=$MYSQL_BPMS_SCHEMA\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf

# business-central
if [ "$BUSINESS_CENTRAL" = "true" ]
then
  echo "JAVA_OPTS=\"\$JAVA_OPTS -Dorg.uberfire.nio.git.ssh.enabled=true\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
  echo "JAVA_OPTS=\"\$JAVA_OPTS -Dorg.uberfire.nio.git.daemon.enabled=true\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
  echo "JAVA_OPTS=\"\$JAVA_OPTS -Dorg.uberfire.nio.git.daemon.host=0.0.0.0\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
  echo "JAVA_OPTS=\"\$JAVA_OPTS -Dorg.uberfire.nio.git.ssh.host=0.0.0.0\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
  echo "JAVA_OPTS=\"\$JAVA_OPTS -Dorg.uberfire.ext.security.management.api.userManagementServices=WildflyCLIUserManagementService\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
  echo "JAVA_OPTS=\"\$JAVA_OPTS -Dorg.uberfire.ext.security.management.wildfly.cli.host=localhost\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
  echo "JAVA_OPTS=\"\$JAVA_OPTS -Dorg.uberfire.ext.security.management.wildfly.cli.port=9999\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
  echo "JAVA_OPTS=\"\$JAVA_OPTS -Dorg.guvnor.m2repo.dir=$BPMS_DATA_DIR/m2/repository\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
  echo "JAVA_OPTS=\"\$JAVA_OPTS -Dorg.uberfire.nio.git.dir=$BPMS_DATA_DIR/$REPO_DIR\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
  echo "JAVA_OPTS=\"\$JAVA_OPTS -Dorg.uberfire.metadata.index.dir=$BPMS_DATA_DIR/$REPO_DIR\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
fi

# business-central as kie-server controller
if [ "$BUSINESS_CENTRAL" = "true" -a "$KIE_SERVER_CONTROLLER" = "true" ]
then
  echo "JAVA_OPTS=\"\$JAVA_OPTS -Dorg.kie.server.user=jboss\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
  echo "JAVA_OPTS=\"\$JAVA_OPTS -Dorg.kie.server.pwd=bpms\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
elif [ "$BUSINESS_CENTRAL" = "true" ]
then
  echo "#JAVA_OPTS=\"\$JAVA_OPTS -Dorg.kie.server.user=jboss\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
  echo "#JAVA_OPTS=\"\$JAVA_OPTS -Dorg.kie.server.pwd=bpms\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
fi

# kie-server
if [ "$KIE_SERVER" = "true" ]
then
  echo "JAVA_OPTS=\"\$JAVA_OPTS -Dorg.kie.server.id=kie-server-$IP_ADDR\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf  
  echo "JAVA_OPTS=\"\$JAVA_OPTS -Dorg.kie.server.location=http://${IP_ADDR}:${KIE_SERVER_PORT}/kie-server/services/rest/server\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
  echo "JAVA_OPTS=\"\$JAVA_OPTS -Dorg.jbpm.server.ext.disabled=$BPMS_EXT_DISABLED\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
  echo "JAVA_OPTS=\"\$JAVA_OPTS -Dorg.drools.server.ext.disabled=$BRMS_EXT_DISABLED\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
  echo "JAVA_OPTS=\"\$JAVA_OPTS -Dorg.optaplanner.server.ext.disabled=$BRP_EXT_DISABLED\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
  echo "JAVA_OPTS=\"\$JAVA_OPTS -Dorg.jbpm.ui.server.ext.disabled=$JBPMUI_EXT_DISABLED\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
  echo "JAVA_OPTS=\"\$JAVA_OPTS -Dorg.kie.server.repo=$BPMS_DATA_DIR\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
  echo "JAVA_OPTS=\"\$JAVA_OPTS -Dorg.kie.server.bypass.auth.user=$KIE_SERVER_BYPASS_AUTH_USER\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
fi

# kie-server with bypass auth user
if [ "$KIE_SERVER" = "true" -a "$KIE_SERVER_BYPASS_AUTH_USER" = "true" ]
then
  echo "JAVA_OPTS=\"\$JAVA_OPTS -Dorg.jbpm.ht.callback=props\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
  echo "JAVA_OPTS=\"\$JAVA_OPTS -Djbpm.user.group.mapping=file:${BPMS_HOME}/${BPMS_ROOT}/standalone/configuration/application-roles.properties\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
  echo "JAVA_OPTS=\"\$JAVA_OPTS -Dorg.jbpm.ht.userinfo=props\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
  echo "JAVA_OPTS=\"\$JAVA_OPTS -Djbpm.user.info.properties=file:${BPMS_HOME}/${BPMS_ROOT}/standalone/configuration/bpms-userinfo.properties\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf  
elif [ "$KIE_SERVER" = "true" ]
then
  echo "JAVA_OPTS=\"\$JAVA_OPTS -Dorg.jbpm.ht.callback=jaas\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
  echo "JAVA_OPTS=\"\$JAVA_OPTS -Dorg.jbpm.ht.userinfo=props\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf  
  echo "JAVA_OPTS=\"\$JAVA_OPTS -Djbpm.user.info.properties=file:${BPMS_HOME}/${BPMS_ROOT}/standalone/configuration/bpms-userinfo.properties\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
fi

# managed kie-server
KIE_SERVER_CONTROLLER_IP=$IP_ADDR
if [ "$KIE_SERVER" = "true" -a "$KIE_SERVER_MANAGED" = "true" ] 
then
  echo "JAVA_OPTS=\"\$JAVA_OPTS -Dorg.kie.server.controller=http://${KIE_SERVER_CONTROLLER_IP}:8080/business-central/rest/controller\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
  echo "JAVA_OPTS=\"\$JAVA_OPTS -Dorg.kie.server.controller.user=kieserver\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
  echo "JAVA_OPTS=\"\$JAVA_OPTS -Dorg.kie.server.controller.pwd=kieserver1!\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
elif [ "$KIE_SERVER" = "true" ]
then
  echo "#JAVA_OPTS=\"\$JAVA_OPTS -Dorg.kie.server.controller=http://${KIE_SERVER_CONTROLLER_IP}:8080/business-central/rest/controller\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
  echo "#JAVA_OPTS=\"\$JAVA_OPTS -Dorg.kie.server.controller.user=kieserver\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
  echo "#JAVA_OPTS=\"\$JAVA_OPTS -Dorg.kie.server.controller.pwd=kieserver1!\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf

fi

# quartz properties
#echo "JAVA_OPTS=\"\$JAVA_OPTS -Dorg.quartz.properties=${BPMS_HOME}/${BPMS_ROOT}/standalone/configuration/quartz.properties\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf

# kie-server persistence settings
#echo "JAVA_OPTS=\"\$JAVA_OPTS -Dorg.kie.server.persistence.ds=java:jboss/datasources/jbpmDS\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf
#echo "JAVA_OPTS=\"\$JAVA_OPTS -Dorg.kie.server.persistence.dialect=org.hibernate.dialect.MySQL5Dialect\"" >> $BPMS_HOME/$BPMS_ROOT/bin/standalone.conf

exit 0
