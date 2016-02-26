#!/bin/sh

DOCKER_IP=$(ip addr show eth0 | grep -E '^\s*inet' | grep -m1 global | awk '{ print $2 }' | sed 's|/.*||')

START_LOG_FILE=/tmp/start-bpms.log

DATABASE_SERVICE_NAME_UC=$(echo $DATABASE_SERVICE_NAME | tr [a-z] [A-Z])

echo -en "STARTING BPMS ${JBOSS_BPMS_VERSION}\nDOCKER_IP = $DOCKER_IP\n" > $START_LOG_FILE

echo -en "DATABASE_SERVICE_NAME = $DATABASE_SERVICE_NAME_UC\n" >> $START_LOG_FILE

DATABASE_SERVICE_NAME_SERVICE_HOST=$(eval "echo \$$(echo $DATABASE_SERVICE_NAME_UC)_SERVICE_HOST")

DATABASE_SERVICE_NAME_SERVICE_PORT=$(eval "echo \$$(echo $DATABASE_SERVICE_NAME_UC)_SERVICE_PORT")

echo -en "DATABASE_SERVICE_NAME_HOST = ${DATABASE_SERVICE_NAME_SERVICE_HOST}:${DATABASE_SERVICE_NAME_SERVICE_PORT}\n" >> $START_LOG_FILE

JBOSS_COMMON_ARGS="-Djboss.bind.address=$DOCKER_IP -Djboss.bind.address.management=$DOCKER_IP -Djboss.node.name=server-$DOCKER_IP"

BPMS_COMMON_ARGS="-Dorg.uberfire.nio.git.daemon.host=$DOCKER_IP -Dorg.uberfire.nio.git.ssh.host=$DOCKER_IP"

if [ "x$DATABASE_SERVICE_NAME_UC" != "x" ]; then
    MYSQL_ARGUMENTS=" -Dmysql.host.ip=$DATABASE_SERVICE_NAME_SERVICE_HOST -Dmysql.host.port=$DATABASE_SERVICE_NAME_SERVICE_PORT"
else
    echo -en "DATABASE_SERVICE_NAME_UC not set !\n" >> $START_LOG_FILE
fi

# configuration

if [ ! -d "$JBOSS_BPMS_DATA/configuration" ]; then
  cp -r $JBOSS_HOME/standalone/configuration $JBOSS_BPMS_DATA 
fi

$JBOSS_HOME/bin/standalone.sh --server-config=standalone.xml -Djboss.server.config.dir=$JBOSS_BPMS_DATA/configuration $JBOSS_COMMON_ARGS $BPMS_COMMON_ARGS $MYSQL_ARGUMENTS 0<&- &>/dev/null



