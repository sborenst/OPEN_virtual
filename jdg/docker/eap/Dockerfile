FROM ce-registry.usersys.redhat.com/jboss-eap-6/eap:6.4
MAINTAINER "JA Bride"

# BUILD PROCEDURE
# start Red Hat VPN
# cd $CONTAINER_HOME
# git clone https://github.com/redhat-gpe/OPEN_docker.git
# cd $CONTAINER_HOME/OPEN_docker/jdg/docker/eap
# docker build --rm -t gpe-eap-jdg .

# START PROCEDURE
docker run -p 10080:8080 -p 11990:9990  -p 11999:9999 -d --name=eap-jdg gpe-eap-jdg
nsenter -m -u -n -i -p -t `docker inspect --format '{{ .State.Pid }}' eap-jdg` /bin/bash

# Expose management HTTP and CLI
EXPOSE 9990 9999

####### RDBMS DRIVERS ############
USER root
RUN yum install -y postgresql-jdbc postgresql-jdbc mysql-connector-java iproute && yum clean all -y

ENV JBOSS_CONFIG standalone.xml
ENV JBOSS_NAME jboss-eap-6.4
ENV START_LOG_FILE=/tmp/start-eap.log
ENV JDG_MODULES_NAME=jboss-datagrid-6.5.0-eap-modules-library
ENV JDG_MODULES_ZIP=jboss-datagrid-6.5.0.Beta-eap-modules-library.zip
ENV JDG_MODULES_ZIP_PATH=/resources/$JDG_MODULES_ZIP

######  Layer JDG modules on EAP ####
ADD ./resources /resources
RUN unzip -o $JDG_MODULES_ZIP_PATH -d /tmp/ && \
    cp -rf /tmp/$JDG_MODULES_NAME/modules/* $JBOSS_HOME/modules/system/layers/base && \
    rm -rf $JDG_MODULES_ZIP_PATH && \
    rm -rf /tmp/$JDG_MODULES_NAME

ADD ./config $CONTAINER_CONFIG


#CMD ["/opt/bpm-bpmsuite/config/start-bpms.sh"]
