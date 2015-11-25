# docker build --rm=true -t redhat-gpe/bpms .
# docker tag -f redhat-gpe/bpms infranode00-mwl.localdomain:5000/redhat-gpe/bpms
# docker push infranode00-mwl.localdomain:5000/redhat-gpe/bpms

FROM redhat-gpe/jboss-base-jdk8:latest

USER root

ENV LAUNCH_JBOSS_IN_BACKGROUND="true" \
    JBOSS_PRODUCT="bpms" \
    JBOSS_EAP_VERSION="6.4.4" \
    JBOSS_BPMS_VERSION="6.2.0.CR1" \
    JBOSS_HOME="/opt/bpms" \
    JBOSS_BPMS_DATA="/opt/open-bpms/data" \
    JBOSS_BPMS_CONFIG="/opt/open-bpms/config"

RUN yum install -y mysql-connector-java iproute && \ 
    yum clean all -y

ADD ./resources scripts /scripts/
ADD ./config /opt/open-bpms/config/

RUN chmod 755 /scripts/*.sh && \
    /scripts/install_as_root.sh

# Necessary to permit running with a randomised UID
RUN chmod -R a+rwx /opt/bpms /opt/open-bpms/

VOLUME ["/opt/open-bpms/data"]

EXPOSE 9999 8080 9990

USER 185

CMD ["/opt/open-bpms/config/start-container.sh"]
