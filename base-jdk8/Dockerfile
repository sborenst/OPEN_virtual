# docker build --rm=true -t redhat-gpe/jboss-base-jdk8 .

FROM redhat-gpe/jboss-base:latest

ENV JAVA_HOME="/usr/lib/jvm/java-1.8.0" \
    JAVA_VENDOR="openjdk" \
    JAVA_VERSION="1.8.0"

USER root

# Install JDK 8
RUN yum -y install java-1.8.0-openjdk-devel && \
    yum clean all

USER jboss
