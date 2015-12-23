FROM ce-registry.usersys.redhat.com/jboss-eap-6/eap:6.4-153
MAINTAINER "JA Bride"

# BUILD PROCEDURE
# start Red Hat VPN
# cd $CONTAINER_HOME
# git clone https://github.com/redhat-gpe/OPEN_docker.git
# cd $CONTAINER_HOME/OPEN_docker/jdg/docker/eap
# docker build --rm -t gpe-jdg-eap .

# START PROCEDURE
# docker run -p 10080:8080 -p 11990:9990  -p 11999:9999 -d --volumes-from=jdg-storage -e JBOSS_CONFIG=standalone-ha.xml --name=jdg-eap gpe-jdg-eap
# nsenter -m -u -n -i -p -t `docker inspect --format '{{ .State.Pid }}' jdg-eap` /bin/bash

# Expose management HTTP and CLI
EXPOSE 9990 9999

####### RDBMS DRIVERS ############
USER root
RUN yum install -y postgresql-jdbc postgresql-jdbc mysql-connector-java iproute && yum clean all -y

ENV JBOSS_CONFIG standalone.xml
ENV JBOSS_NAME jboss-eap-6.4
ENV START_LOG_FILE=/tmp/start-eap.log
ENV JDG_MODULES_NAME=jboss-datagrid-6.5.1-eap-modules-library
ENV JDG_MODULES_ZIP=jboss-datagrid-6.5.1-eap-modules-library.zip
ENV JDG_MODULES_ZIP_PATH=/resources/$JDG_MODULES_ZIP

######  Layer JDG modules on EAP ####
ADD ./resources /resources
RUN unzip -o $JDG_MODULES_ZIP_PATH -d /tmp/ && \
    cp -rf /tmp/$JDG_MODULES_NAME/modules/* $JBOSS_HOME/modules/system/layers/base && \
    rm -rf $JDG_MODULES_ZIP_PATH && \
    rm -rf /tmp/$JDG_MODULES_NAME

ADD ./config/mgmt-users.properties $JBOSS_HOME/standalone/configuration/mgmt-users.properties
ADD ./config/start-eap.sh $JBOSS_HOME/bin/start-eap.sh
RUN chown -R jboss:jboss $JBOSS_HOME

USER jboss
CMD ["/opt/eap/bin/start-eap.sh"]
