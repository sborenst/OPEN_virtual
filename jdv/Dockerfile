#FROM docker-registry.usersys.redhat.com/goldmann/jboss-datavirt:latest
FROM jboss-datavirt:6.1
MAINTAINER JA Bride <jbride@redhat.com>

# BUILD PROCEDURE
# cd $CONTAINER_HOME
# git clone http://git.app.eng.bos.redhat.com/git/jboss-dockerfiles.git
# git clone https://github.com/redhat-gpe/OPEN_docker.git
# cd $CONTAINER_HOME/jboss-dockerfiles/standalone/datavirt/6.1
# git checkout gpe
# docker build --rm -t jboss-datavirt:6.1 .
# cd $CONTAINER_HOME/OPEN_docker/jdv
# docker build --rm -t gpe-datavirt .

# START PROCEDURE
# docker run -p 9080:8080 -p 10990:9990  -p 10999:9999 -p 36432:35432 -p 32000:31000 --link=gpe-pgsql:postgresql -d --name=jdv gpe-datavirt

# SHELL ACCESS TO JDV CONTAINER
# nsenter -m -u -n -i -p -t  `docker inspect --format '{{ .State.Pid }}' jdv` /bin/bash

# BROWSER ACCESS TO JDV WEB APPLICATIONS
# https://<docker_host>:10990                       :    admin / brms
# http://<docker_host>:9080/dashboard/              :    dashboardAdmin / Fake-pwd1
# http://<docker_host>:9080/modeshape-cmis/         :    modeshapeUser / Fake-pwd1

USER root

####### RDBMS DRIVERS ############
RUN yum install -y postgresql-jdbc

ENV CONTAINER_CONFIG /opt/OPEN-jdv/config

# Expose the following ports:
# 9999:   EAP management port so as to support creation of a remote server instance in JBDS
# 35432:  ODBC port
# 31000:  JDBC port
EXPOSE 9999 35432 31000

RUN mkdir -p $CONTAINER_CONFIG

ADD ./config/start-container.sh $CONTAINER_CONFIG/start-container.sh
ADD ./config/postgresql-setup.cli $CONTAINER_CONFIG/postgresql-setup.cli
ADD ./config/mgmt-users.properties $JBOSS_HOME/standalone/configuration/mgmt-users.properties
ADD ./config/modules $JBOSS_HOME/modules/system/layers/dv
RUN ln -sf -t $JBOSS_HOME/modules/system/layers/dv/org/postgresql/jdbc/main /usr/share/java/postgresql-jdbc.jar
RUN chown -R jboss:1000 $CONTAINER_CONFIG
RUN chown -R jboss:1000 $JBOSS_HOME

# start eap in admin-only mode
USER jboss
RUN $JBOSS_HOME/bin/standalone.sh --server-config=standalone.xml --admin-only & \
    sleep 15s &&\
    $JBOSS_HOME/bin/jboss-cli.sh --connect --file=$CONTAINER_CONFIG/postgresql-setup.cli


CMD ["/opt/OPEN-jdv/config/start-container.sh"]
