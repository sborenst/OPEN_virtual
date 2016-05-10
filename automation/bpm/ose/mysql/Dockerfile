FROM centos:7.2.1511

# docker build --rm=true -t redhat-gpe/bpms-mysql .
# docker tag -f redhat-gpe/bpms-mysql infranode00-ml.localdomain:5000/redhat-gpe/bpms-mysql
# docker push infranode00-ml.localdomain:5000/redhat-gpe/bpms-mysql
# docker run -d --name="gpe-bpm-mysql" redhat-gpe/bpms-mysql

ENV HOME=/var/lib/mysql

EXPOSE 3306

RUN yum -y update && \
    yum -y --setopt=tsflags=nodocs install mariadb mariadb-server gettext && \
    yum clean all && \
    mkdir -p /var/lib/mysql/data && chown -R mysql.0 /var/lib/mysql

COPY contrib /var/lib/mysql/
COPY run-*.sh /usr/local/bin/
ADD ./sql /sql

# Loosen permission bits for group to avoid problems running container with
# arbitrary UID
# When only specifying user, group is 0, that's why /var/lib/mysql must have
# owner mysql.0; that allows to avoid a+rwx for this dir
RUN chmod -R g+rwx /var/lib/mysql && \
    chmod 755 /usr/local/bin/run-*.sh

VOLUME ["/var/lib/mysql/data"]

# Allows for mysql command line prompt within running container
ENV TERM=xterm-256color

USER 27

ENTRYPOINT ["run-mysqld.sh"]
CMD ["mysqld_safe"]



