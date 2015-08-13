FROM rhel7
MAINTAINER JA Bride

# BUILD PROCEDURE
# cd $CONTAINER_HOME
# git clone https://github.com/redhat-gpe/OPEN-docker.git
# cd $CONTAINER_HOME/OPEN-docker/postgresql
# docker build --rm -t gpe-jdv-pgsql .

# START PROCEDURE
# docker run -p 6432:5432 -d --name=gpe-jdv-pgsql gpe-jdv-pgsql

# BASH SHELL ACCESS TO JDV CONTAINER
# nsenter -m -u -n -i -p -t  `docker inspect --format '{{ .State.Pid }}' gpe-jdv-pgsql` /bin/bash

# PSQL SHELL
# 	psql -U postgres -h docker1.ose.opentlc.com -p 6432 postgres
#       \l   

RUN yum -y update; yum clean all

# Install postgresql deps
RUN rpm -Uvh http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-5.noarch.rpm
RUN rpm -Uvh http://yum.postgresql.org/9.3/redhat/rhel-7-x86_64/pgdg-redhat93-9.3-1.noarch.rpm
RUN yum install -y procps-ng postgresql93 postgresql93-contrib postgresql93-server libxslt hostname && yum clean all -y

#
# set up cluster directory
#
RUN mkdir -p /cluster/bin
RUN mkdir -p /pgdata

# set environment vars
ENV PGROOT /usr/pgsql-9.3
ENV PGDATA /pgdata

# add path settings for postgres user
ADD conf/.bash_profile /var/lib/pgsql/

# add volumes to allow backup of postgres files
#VOLUME ["/pgdata"]

# open up the postgres port
EXPOSE 5432

ADD bin /cluster/bin
ADD conf /cluster/conf
RUN chown -R postgres:postgres /cluster
RUN chown -R postgres:postgres /pgdata
RUN chown -R postgres:postgres /var/lib/pgsql

USER postgres

CMD ["/cluster/bin/start-pg-standalone.sh"]
