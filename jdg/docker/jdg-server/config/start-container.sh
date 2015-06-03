#!/bin/sh

START_LOG_FILE=/tmp/start-jdg.log

DOCKER_IP=$(ip addr show eth0 | grep -E '^\s*inet' | grep -m1 global | awk '{ print $2 }' | sed 's|/.*||')

echo -en "JBOSS_CONFIG = $JBOSS_CONFIG\n" >> $START_LOG_FILE
echo -en "STARTING JDG CONTAINER\nDOCKER_IP = $DOCKER_IP\n" > $START_LOG_FILE

JBOSS_COMMON_ARGS="--server-config=$JBOSS_CONFIG -Djboss.bind.address=$DOCKER_IP -Djboss.bind.address.management=$DOCKER_IP "

# customize size of JVM heap
JAVA_OPTS="-Xms128m -Xmx1303m -XX:MaxPermSize=256m -Djava.net.preferIPv4Stack=true -Djboss.modules.system.pkgs=$JBOSS_MODULES_SYSTEM_PKGS -Djava.awt.headless=true -Djboss.modules.policy-permissions=true"
export JAVA_OPTS
$JBOSS_HOME/bin/standalone.sh $JBOSS_COMMON_ARGS $PGSQL_ARGUMENTS >> $START_LOG_FILE 2>&1
