FROM docker-registry.usersys.redhat.com/cloud_enablement/jboss-base-jdk7:latest
MAINTAINER JA Bride <jbride@redhat.com>

# BUILD PROCEDURE
# start Red Hat VPN
# cd $CONTAINER_HOME
# git clone https://github.com/redhat-gpe/OPEN_docker.git
# cd $CONTAINER_HOME/OPEN_docker/jdg/docker
# docker build --rm -t gpe-datagrid .

# START PROCEDURE
# docker run -p 10080:8080 -p 11990:9990  -p 11999:9999 -p 13222:11222 -p 13221:11221 -d --name=jdg gpe-datagrid

# SHELL ACCESS TO JDG CONTAINER
# nsenter -m -u -n -i -p -t  `docker inspect --format '{{ .State.Pid }}' jdg` /bin/bash

# BROWSER ACCESS TO JDG WEB APPLICATIONS
# https://<docker_host>:10990                       :    admin / jb0ssredhat!

USER root


ENV CONTAINER_CONFIG /opt/OPEN-jdg/config
ENV JBOSS_HOME /opt/jboss-datagrid-6.4.0-server

# Expose the following ports:
# 9990:   EAP web management port
# 9999:   EAP management port so as to support creation of a remote server instance in JBDS
# 11222:  Hot-Rod protocol
# 11221:  Memcached protocol
EXPOSE 8080 9990 9999 11222 11211

RUN mkdir -p $CONTAINER_CONFIG

ADD ./downloads/jboss-datagrid-6.4.0-server.zip $CONTAINER_CONFIG/jboss-datagrid-6.4.0-server.zip

RUN unzip $CONTAINER_CONFIG/jboss-datagrid-6.4.0-server.zip -d /opt && \
    rm $CONTAINER_CONFIG/jboss-datagrid-6.4.0-server.zip

ADD ./config/start-container.sh $CONTAINER_CONFIG/start-container.sh
ADD ./config/mgmt-users.properties $JBOSS_HOME/standalone/configuration/mgmt-users.properties
RUN chown -R jboss:1000 /opt

RUN yum install -y iproute

CMD ["/opt/OPEN-jdg/config/start-container.sh"]
