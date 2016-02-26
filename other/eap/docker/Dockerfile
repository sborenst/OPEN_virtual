FROM jboss-base-jdk8:latest

USER root

ENV LAUNCH_JBOSS_IN_BACKGROUND="true" \
    JBOSS_EAP_VERSION="6.4.0" \
    JBOSS_HOME="/opt/jboss" \
    JBOSS_EAP_DATA="/opt/open-eap/data" \
    JBOSS_EAp_CONFIG="/opt/open-eap/config"

RUN yum install -y mysql-connector-java iproute && \ 
    yum clean all -y

ADD ./resources scripts /scripts/
ADD ./config /opt/open-eap/config/

RUN chmod 755 /scripts/*.sh && \
    /scripts/install_as_root.sh

# Necessary to permit running with a randomised UID
RUN chmod -R a+rwx /opt/eap /opt/open-eap/

VOLUME ["/opt/open-eap/data"]

EXPOSE 9999 8080 9990

USER 185

CMD ["/opt/open-eap/config/start-container.sh"]
