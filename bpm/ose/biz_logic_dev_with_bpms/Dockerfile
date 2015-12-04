# docker build --rm=true -t redhat-gpe/biz_logic_dev .
# docker tag -f redhat-gpe/biz_logic_dev infranode00-mwl.localdomain:5000/redhat-gpe/biz_logic_dev
# docker push infranode00-mwl.localdomain:5000/redhat-gpe/biz_logic_dev

FROM redhat-gpe/bpms:latest

USER 185

ENV $DOMAIN_JAR_FILE=""

ADD ./resources/biz_logic_dev/$DOMAIN_JAR_FILE $JBOSS_HOME/standalone/deployments/business-central.war/WEB-INF/lib/$DOMAIN_JAR_FILE
