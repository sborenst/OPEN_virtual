FROM ce-registry.usersys.redhat.com/jboss-base-7/jdk8:latest
MAINTAINER JA Bride <jbride@redhat.com>

# BUILD PROCEDURE
# start Red Hat VPN
# cd $CONTAINER_HOME
# git clone https://github.com/redhat-gpe/OPEN_docker.git
# cd $CONTAINER_HOME/OPEN_docker/jdg/docker/jdg
# docker build --rm -t gpe-jdg-server .

# START PROCEDURE
# docker run -p 8080:8080 -p 9999:9999 -p 11222:11222 -p 11221:11221 --volumes-from=jdg-storage -e JBOSS_CONFIG=clustered.xml -d --name=jdg-server gpe-jdg-server

# SHELL ACCESS TO JDG CONTAINER
# nsenter -m -u -n -i -p -t  `docker inspect --format '{{ .State.Pid }}' jdg` /bin/bash

# BROWSER ACCESS TO JDG WEB APPLICATIONS
# https://<docker_host>:10990                       :    admin / jb0ssredhat!

USER root


ENV CONTAINER_CONFIG /opt/OPEN-jdg/config
ENV JBOSS_HOME /opt/jboss-datagrid-6.5.0-server
ENV JBOSS_CONFIG standalone.xml

# Expose the following ports:
# 9990:   EAP web management port
# 9999:   EAP management port so as to support creation of a remote server instance in JBDS
# 11222:  Hot-Rod protocol
# 11221:  Memcached protocol
EXPOSE 8080 9990 9999 11222 11211

RUN mkdir -p $CONTAINER_CONFIG

ADD ./resources/jboss-datagrid-6.5.1-server.zip $CONTAINER_CONFIG/jboss-datagrid-6.5.1-server.zip

RUN unzip $CONTAINER_CONFIG/jboss-datagrid-6.5.1-server.zip -d /opt && \
    rm $CONTAINER_CONFIG/jboss-datagrid-6.5.1-server.zip

ADD ./config/start-container.sh $CONTAINER_CONFIG/start-container.sh
ADD ./config/mgmt-users.properties $JBOSS_HOME/standalone/configuration/mgmt-users.properties

RUN ln -s $JBOSS_HOME /opt/eap
RUN chown -R jboss:jboss $JBOSS_HOME

RUN yum install -y iproute && yum clean all -y

USER jboss
CMD ["/opt/OPEN-jdg/config/start-container.sh"]
