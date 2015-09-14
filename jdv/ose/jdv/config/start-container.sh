#!/bin/sh

JBOSS_HOME=/opt/jboss-eap-6.3/
CONTAINER_CONFIG=/opt/OPEN-jdv/config
START_LOG_FILE=/tmp/start-jdv.log

DOCKER_IP=$(ip addr show eth0 | grep -E '^\s*inet' | grep -m1 global | awk '{ print $2 }' | sed 's|/.*||')

DATABASE_SERVICE_NAME_UC=$(echo $DATABASE_SERVICE_NAME | tr [a-z] [A-Z])

echo -en "STARTING JDV CONTAINER\nDOCKER_IP = $DOCKER_IP\n" > $START_LOG_FILE

echo -en "DATABASE_SERVICE_NAME = $DATABASE_SERVICE_NAME_UC\n" >> $START_LOG_FILE

DATABASE_SERVICE_NAME_SERVICE_HOST=$(eval "echo \$$(echo $DATABASE_SERVICE_NAME_UC)_SERVICE_HOST")

DATABASE_SERVICE_NAME_SERVICE_PORT=$(eval "echo \$$(echo $DATABASE_SERVICE_NAME_UC)_SERVICE_PORT")

echo -en "DATABASE_SERVICE_NAME_HOST = ${DATABASE_SERVICE_NAME_SERVICE_HOST}:${DATABASE_SERVICE_NAME_SERVICE_PORT}\n" >> $START_LOG_FILE

JBOSS_COMMON_ARGS="-Djboss.bind.address=$DOCKER_IP -Djboss.bind.address.management=$DOCKER_IP "

if [ "x$DATABASE_SERVICE_NAME_UC" != "x" ]; then
    PGSQL_ARGUMENTS=" -Dpgsql.jdv.driver=postgresql -Dpgsql.jdv.user=jdv -Dpgsql.jdv.password=jdv"
    PGSQL_ARGUMENTS=" $PGSQL_ARGUMENTS -Dpgsql.jdv.connection_url=jdbc:postgresql://${DATABASE_SERVICE_NAME_SERVICE_HOST}:${DATABASE_SERVICE_NAME_SERVICE_PORT}/ "
else
    echo -en "DATABASE_SERVICE_NAME_UC not set !\n" >> $START_LOG_FILE
fi

echo -en "START ARGUMENTS = $PGSQL_ARGUMENTS \n" >> $START_LOG_FILE

# customize size of JVM heap
JAVA_OPTS="-Xms128m -Xmx1303m -XX:MaxPermSize=256m -Djava.net.preferIPv4Stack=true -Djboss.modules.system.pkgs=$JBOSS_MODULES_SYSTEM_PKGS -Djava.awt.headless=true -Djboss.modules.policy-permissions=true"
export JAVA_OPTS
$JBOSS_HOME/bin/standalone.sh --server-config=standalone.xml $JBOSS_COMMON_ARGS $PGSQL_ARGUMENTS >> $START_LOG_FILE 2>&1
