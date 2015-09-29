#!/bin/bash

set -e

SCRIPTS_DIR=$(dirname $0)
EAP_DISTRIBUTION_ZIP=jboss-eap-6.4.0.zip
BPMS_DISTRIBUTION_ZIP=jboss-bpmsuite-6.1.0.GA-deployable-eap6.x.zip
EAP_VERSION=6.4

MAVEN_REPO_DIR=$JBOSS_BPMS_DATA/m2/repository

QUARTZ_PROPERTIES=$JBOSS_BPMS_CONFIG/quartz.properties

MYSQL_DRIVER_JAR=mysql-connector-java.jar
MYSQL_DRIVER_JAR_DIR=/usr/share/java
MYSQL_MODULE_NAME=com.mysql

CLI_BPMS=$JBOSS_BPMS_CONFIG/bpms.cli
CLI_BPMS_QUARTZ=$JBOSS_BPMS_CONFIG/bpms-quartz.cli

JBOSS_CONFIG=standalone.xml

mkdir -p $JBOSS_BPMS_DATA

echo "Unzipping EAP"
unzip -q $SCRIPTS_DIR/$EAP_DISTRIBUTION_ZIP

echo "Unzipping BPMS"
unzip -q -o $SCRIPTS_DIR/$BPMS_DISTRIBUTION_ZIP

mv jboss-eap-$EAP_VERSION $JBOSS_HOME

echo "Remove org.kie.example"
sed -i 's/property name="org.kie.example" value="true"/property name="org.kie.example" value="false"/' $JBOSS_HOME/standalone/configuration/standalone.xml

echo "set system variables for maven and git repos"
echo $'\n' >> $SERVER_INSTALL_DIR/$SERVER_NAME/bin/standalone.conf
echo "JAVA_OPTS=\"\$JAVA_OPTS -Dorg.guvnor.m2repo.dir=$JBOSS_BPMS_DATA/m2/repository \"" >> $JBOSS_HOME/bin/standalone.conf
echo "JAVA_OPTS=\"\$JAVA_OPTS -Dorg.uberfire.nio.git.dir=$JBOSS_BPMS_DATA/bpms-repo \"" >> $JBOSS_HOME/bin/standalone.conf
echo "JAVA_OPTS=\"\$JAVA_OPTS -Dorg.uberfire.metadata.index.dir=$JBOSS_BPMS_DATA/bpms-repo \"" >> $JBOSS_HOME/bin/standalone.conf
echo "JAVA_OPTS=\"\$JAVA_OPTS -Dkie.maven.settings.custom=$JBOSS_BPMS_CONFIG/settings.xml \"" >> $JBOSS_HOME/bin/standalone.conf

echo "Setup local maven repo"
touch $JBOSS_BPMS_CONFIG/settings.xml
echo "<settings><localRepository>$MAVEN_REPO_DIR</localRepository></settings>" >> $JBOSS_BPMS_CONFIG/settings.xml

echo "Create application user jboss:bpms"
echo $'\n' >> $JBOSS_HOME/standalone/configuration/application-users.properties
echo "jboss=16cc751119998a45f35b2045b858e747" >> $JBOSS_HOME/standalone/configuration/application-users.properties

echo $'\n' >> $JBOSS_HOME/standalone/configuration/application-roles.properties
echo "jboss=admin,analyst,user,reviewer,kie-server,kiemgmt" >> $JBOSS_HOME/standalone/configuration/application-roles.properties

echo "Create management user admin:admin"
echo $'\n' >> $JBOSS_HOME/standalone/configuration/mgmt-users.properties
echo "admin=c22052286cd5d72239a90fe193737253" >> $JBOSS_HOME/standalone/configuration/mgmt-users.properties

# Quartz Properties
echo "Copy quartz properties file"
cp $QUARTZ_PROPERTIES $JBOSS_HOME/standalone/configuration

# Modify persistence.xml
echo "Modify persistence.xml"
sed -i s/java:jboss\\/datasources\\/ExampleDS/java:jboss\\/datasources\\/jbpmDS/ $JBOSS_HOME/standalone/deployments/business-central.war/WEB-INF/classes/META-INF/persistence.xml
sed -i s/org.hibernate.dialect.H2Dialect/org.hibernate.dialect.MySQL5Dialect/ $JBOSS_HOME/standalone/deployments/business-central.war/WEB-INF/classes/META-INF/persistence.xml

# Configure dashboard
echo "Configure Dashboard app"
sed -i s/java:jboss\\/datasources\\/ExampleDS/java:jboss\\/datasources\\/jbpmDS/ $JBOSS_HOME/standalone/deployments/dashbuilder.war/WEB-INF/jboss-web.xml

# Set permissions
chmod 0755 $JBOSS_HOME
chown -R jboss:jboss $JBOSS_HOME $JBOSS_BPMS_DATA $JBOSS_BPMS_CONFIG

# Configure the server
echo "Configure the Server"
# replace placeholders in cli file
VARS=( MYSQL_MODULE_NAME MYSQL_DRIVER_JAR MYSQL_DRIVER_JAR_DIR )
for i in "${VARS[@]}"
do
    sed -i "s'@@${i}@@'${!i}'" $CLI_BPMS	
done
$JBOSS_HOME/bin/standalone.sh --admin-only -c $JBOSS_CONFIG &
sleep 15
$JBOSS_HOME/bin/jboss-cli.sh -c --file=$CLI_BPMS
$JBOSS_HOME/bin/jboss-cli.sh -c --file=$CLI_BPMS_QUARTZ   
$JBOSS_HOME/bin/jboss-cli.sh -c ":shutdown"
sleep 5

rm -rf $SCRIPTS_DIR

exit 0

