FROM docker-registry.usersys.redhat.com/brew/rhel7:1

RUN yum -y update && yum -y install mariadb-server && yum clean all

# dashbuilder appears to make queries that specify lowercase tablenames
# will now make mysql case insensitive
# also, add entry for general_log_file=/tmp/mysql_query.log
RUN awk '/\[mysqld\]/{print;print "lower_case_table_names=1";print "general_log_file=/tmp/mysql_query.log";next}1' /etc/my.cnf > /etc/my.cnf.new
RUN sed -e 's/var\/lib/opt/g' my.cnf.new > /etc/my.cnf
RUN chown -R mysql:mysql /opt/mysql

# Init mysql
RUN mysql_install_db

# Add admin user
RUN /usr/bin/mysqld_safe & \
    sleep 10s &&\
    echo "GRANT ALL ON *.* TO admin@'%' IDENTIFIED BY 'redhat' WITH GRANT OPTION; FLUSH PRIVILEGES" | mysql

# MySQL - create jboss user and bpm suite 6.1 schema
ADD ./sql /sql
ADD /configure.sh /configure.sh
RUN chmod 755 /configure.sh

RUN /configure.sh

#Expose port 3306
EXPOSE 3306

#Entrypoint
ENTRYPOINT ["/bin/bash", "/usr/bin/mysqld_safe"]
