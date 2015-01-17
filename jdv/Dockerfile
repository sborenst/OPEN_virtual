#FROM docker-registry.usersys.redhat.com/goldmann/jboss-datavirt:latest
FROM jboss-datavirt:6.1
MAINTAINER JA Bride <jbride@redhat.com>

# BUILD PROCEDURE
# cd $CONTAINER_HOME
# git clone http://git.app.eng.bos.redhat.com/git/jboss-dockerfiles.git
# git clone https://github.com/redhat-gpe/OPEN-docker.git
# cd $CONTAINER_HOME/jboss-dockerfiles/datavirt/6.1
# docker build --rm -t jboss-datavirt:6.1 .
# cd $CONTAINER_HOME/OPEN-docker/jdv
# docker build --rm -t gpe-datavirt .

# START PROCEDURE
# docker run -p 9080:8080 -p 10990:9990 -d --name=jdv gpe-datavirt

# SHELL ACCESS TO JDV CONTAINER
# nsenter -m -u -n -i -p -t  `docker inspect --format '{{ .State.Pid }}' jdv` /bin/bash

# BROWSER ACCESS TO JDV WEB APPLICATIONS
# https://<docker_host>:10990                       :    admin / brms
# http://<docker_host>:9080/dashboard/              :    dashboardAdmin / Fake-pwd1
# http://<docker_host>:9080/modeshape-cmis/         :    modeshapeUser / Fake-pwd1

USER root
RUN mkdir -p /opt/OPEN-jdv/config

ADD ./config/start-container.sh /opt/OPEN-jdv/config/start-container.sh
ADD ./config/mgmt-users.properties $JBOSS_HOME/standalone/configuration/mgmt-users.properties
RUN chown -R jboss:1000 /opt/OPEN-jdv
RUN chown -R jboss:1000 $JBOSS_HOME/standalone/configuration

USER jboss
CMD ["/opt/OPEN-jdv/config/start-container.sh"]
