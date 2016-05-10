# Purpose
#   Adds integrationTier-domain.jar to biz-central.war/WEB-INF/lib so as to support lab for module 17

# Usage
#   docker build --rm=true -t redhat-gpe/biz_logic_dev .
#   docker tag -f redhat-gpe/biz_logic_dev infranode00-ml.localdomain:5000/redhat-gpe/biz_logic_dev
#   docker push infranode00-ml.localdomain:5000/redhat-gpe/biz_logic_dev
#   docker run -d --name="gpe-biz-logic-dev" --link=gpe-bpm-mysql:mysql redhat-gpe/biz_logic_dev

FROM redhat-gpe/bpms:latest

ENV JBOSS_HOME="/opt/bpms"
ENV DOMAIN_JAR_FILE="integrationTier-domain-1.0.jar"

COPY ./resources/biz_logic_dev/$DOMAIN_JAR_FILE $JBOSS_HOME/standalone/deployments/business-central.war/WEB-INF/lib/$DOMAIN_JAR_FILE

USER 185

CMD ["/opt/open-bpms/config/start-container.sh"]
