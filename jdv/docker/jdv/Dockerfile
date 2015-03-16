FROM docker-registry.usersys.redhat.com/cloud_enablement/jboss-base-jdk7:latest
MAINTAINER JA Bride <jbride@redhat.com>

# BUILD PROCEDURE
# start Red Hat VPN
# cd $CONTAINER_HOME
# git clone https://github.com/redhat-gpe/OPEN_docker.git
# cd $CONTAINER_HOME/OPEN_docker/jdv
# docker build --rm -t gpe-datavirt .

# START PROCEDURE
# docker run -p 9080:8080 -p 10990:9990  -p 10999:9999 -p 36432:35432 -p 32000:31000 --link=gpe-pgsql:postgresql -d --name=jdv gpe-datavirt

# SHELL ACCESS TO JDV CONTAINER
# nsenter -m -u -n -i -p -t  `docker inspect --format '{{ .State.Pid }}' jdv` /bin/bash

# BROWSER ACCESS TO JDV WEB APPLICATIONS
# https://<docker_host>:10990                       :    admin / jb0ssredhat!
# http://<docker_host>:9080/dashboard/              :    dashboardAdmin / jb0ssredhat!
# http://<docker_host>:9080/modeshape-cmis/         :    modeshapeUser / jb0ssredhat!

USER root

####### RDBMS DRIVERS ############
RUN yum install -y postgresql-jdbc

ENV CONTAINER_CONFIG /opt/OPEN-jdv/config
ENV JBOSS_HOME /opt/jboss-eap-6.3

# Expose the following ports:
# 9999:   EAP management port so as to support creation of a remote server instance in JBDS
# 35432:  ODBC port
# 31000:  JDBC port
EXPOSE 9999 35432 31000

RUN mkdir -p $CONTAINER_CONFIG

ADD ./config/auto.xml $CONTAINER_CONFIG/auto.xml
ADD ./downloads/jboss-dv-installer-6.1.0.redhat-3.jar $CONTAINER_CONFIG/jboss-dv-installer-6.1.0.redhat-3.jar

RUN java -jar $CONTAINER_CONFIG/jboss-dv-installer-6.1.0.redhat-3.jar $CONTAINER_CONFIG/auto.xml && \
    rm $CONTAINER_CONFIG/jboss-dv-installer-6.1.0.redhat-3.jar

ADD ./config/start-container.sh $CONTAINER_CONFIG/start-container.sh
ADD ./config/postgresql-setup.cli $CONTAINER_CONFIG/postgresql-setup.cli
ADD ./config/modules $JBOSS_HOME/modules/system/layers/dv
RUN ln -sf -t $JBOSS_HOME/modules/system/layers/dv/org/postgresql/jdbc/main /usr/share/java/postgresql-jdbc.jar
RUN chown -R jboss:1000 /opt

RUN yum install -y iproute

# start eap in admin-only mode
USER jboss
RUN $JBOSS_HOME/bin/standalone.sh --server-config=standalone.xml --admin-only & \
    sleep 15s &&\
    $JBOSS_HOME/bin/jboss-cli.sh --connect --file=$CONTAINER_CONFIG/postgresql-setup.cli

CMD ["/opt/OPEN-jdv/config/start-container.sh"]
