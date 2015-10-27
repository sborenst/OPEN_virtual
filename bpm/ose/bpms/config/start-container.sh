#!/bin/sh

DOCKER_IP=$(ip addr show eth0 | grep -E '^\s*inet' | grep -m1 global | awk '{ print $2 }' | sed 's|/.*||')

START_LOG_FILE=/tmp/start-bpms.log

echo -en "environment variables = \n" > $START_LOG_FILE
env >> $START_LOG_FILE

echo -en "\nSTARTING BPMS ${JBOSS_BPMS_VERSION}\nDOCKER_IP = $DOCKER_IP\n" >> $START_LOG_FILE



# Given an input of "gpe-bpm-mysql", create an output of: GPE_BPM_MYSQL_SERVICE_HOST
DATABASE_SERVICE_NAME_MODIFIED=`eval echo "$DATABASE_SERVICE_NAME" | sed s/-/_/g | awk '{print toupper($0)}'`
echo -en "DATABASE_SERVICE_NAME_MODIFIED = $DATABASE_SERVICE_NAME_MODIFIED\n" >> $START_LOG_FILE
DATABASE_SERVICE_NAME_SERVICE_HOST=$(eval "echo \$$(echo $DATABASE_SERVICE_NAME_MODIFIED)_SERVICE_HOST")

# Given an input of "gpe-bpm-mysql", create an output of: GPE_BPM_MYSQL_SERVICE_PORT
DATABASE_SERVICE_NAME_SERVICE_PORT=$(eval "echo \$$(echo $DATABASE_SERVICE_NAME_MODIFIED)_SERVICE_PORT")

echo -en "DATABASE_SERVICE_NAME_SOCKET = ${DATABASE_SERVICE_NAME_SERVICE_HOST}:${DATABASE_SERVICE_NAME_SERVICE_PORT}\n" >> $START_LOG_FILE

JBOSS_COMMON_ARGS="-Djboss.bind.address=$DOCKER_IP -Djboss.bind.address.management=$DOCKER_IP -Djboss.node.name=server-$DOCKER_IP"

BPMS_COMMON_ARGS="-Dorg.uberfire.nio.git.daemon.host=$DOCKER_IP -Dorg.uberfire.nio.git.ssh.host=$DOCKER_IP"

if [ "x$DATABASE_SERVICE_NAME_MODIFIED" != "x" ]; then
    MYSQL_ARGUMENTS=" -Dmysql.host.ip=$DATABASE_SERVICE_NAME_SERVICE_HOST -Dmysql.host.port=$DATABASE_SERVICE_NAME_SERVICE_PORT"
else
    echo -en "DATABASE_SERVICE_NAME_MODIFIED not set !\n" >> $START_LOG_FILE
fi

# configuration

if [ ! -d "$JBOSS_BPMS_DATA/configuration" ]; then
  cp -r $JBOSS_HOME/standalone/configuration $JBOSS_BPMS_DATA 
fi

echo  -en "\n\n" >> $START_LOG_FILE

$JBOSS_HOME/bin/standalone.sh --server-config=standalone.xml -Djboss.server.config.dir=$JBOSS_BPMS_DATA/configuration $JBOSS_COMMON_ARGS $BPMS_COMMON_ARGS $MYSQL_ARGUMENTS 0<&- &>>/tmp/start-eap.log
