FROM rhel7
MAINTAINER "JA Bride"

BUILD PROCEDURE
# docker build --rm -t gpe-jdg-storage .

# START PROCEDURE
docker run -d --name=jdg-storage gpe-jdg-storage

# Perform updates
RUN yum -y update && yum clean all

# Create user jboss (with Ids that match that of jboss user created in:  http://git.app.eng.bos.redhat.com/git/jboss-dockerfiles.git at base/rhel7/Dockerfile
RUN groupadd -r jboss -g 185 && useradd -u 185 -r -g jboss -d /opt/jboss -s /bin/bash -c "JBoss user" jboss
RUN mkdir -p /opt/shared/jdg-cluster-discovery

# Change permissions to user jboss
RUN chown -R jboss:jboss /opt/shared

# Mount as volume
VOLUME /opt/shared/jdg-cluster-discovery

CMD true
