FROM docker-registry.usersys.redhat.com/brew/rhel7:1

ENV BPMS_SHARED_DIR /opt/shared/bpm
ENV BPMS_GIT_DIR $BPMS_SHARED_DIR/git
ENV BPMS_INDEX_DIR $BPMS_SHARED_DIR/lucene
ENV BPMS_ARTIFACT_REPO_DIR $BPMS_SHARED_DIR/artifact-repo

# Perform updates
RUN yum -y update && yum clean all

# Create user jboss (with Ids that match that of jboss user created in:  http://git.app.eng.bos.redhat.com/git/jboss-dockerfiles.git at base/rhel7/Dockerfile
RUN groupadd -r jboss -g 185 && useradd -u 185 -r -g jboss -d /opt/jboss -s /bin/bash -c "JBoss user" jboss
RUN mkdir -p /opt/shared/hq-journal
RUN mkdir -p /opt/shared/hq-cluster-discovery
RUN mkdir -p $BPMS_GIT_DIR
RUN mkdir -p $BPMS_INDEX_DIR
RUN mkdir -p $BPMS_ARTIFACT_REPO_DIR

# Change permissions to user jboss
RUN chown -R jboss:jboss /opt/shared

RUN groupadd -r mysql && useradd -r -g mysql -s /bin/bash -c "mysql user" mysql
RUN mkdir -p /u01/shared/mysql
RUN chown -R mysql:mysql /u01/shared/mysql

# Mount as volume
VOLUME /opt/shared/hq-journal
VOLUME /opt/shared/hq-cluster-discovery
VOLUME $BPMS_GIT_DIR
VOLUME $BPMS_INDEX_DIR
VOLUME $BPMS_ARTIFACT_REPO_DIR

VOLUME /u01/shared/mysql

CMD true
