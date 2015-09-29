FROM centos:7

RUN yum -y install yum-utils unzip tar && \
    yum clean all

# Create a user and group used to launch processes
# We use the ID 185 fot the group as well as for the user.
# This ID is registered static ID for the JBoss EAP product
# on RHEL which makes it safe to use.
RUN groupadd -r jboss -g 185 && useradd -u 185 -r -g jboss -m -d /home/jboss -s /sbin/nologin -c "JBoss user" jboss

# Set the working directory to jboss' user home directory
WORKDIR /home/jboss

# Specify the user which should be used to execute all commands below
USER jboss

