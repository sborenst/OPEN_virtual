FROM bpm-bpmsuite:latest
MAINTAINER "JA Bride"

# docker build --rm=true -t open-bpmsuite open-bpmsuite
# bpm-bpmsuite/bin/start.sh -c bpm-ui -i open-bpmsuite -useRemoteHQ -useSharedBPMFilesystem -useLinkedMySQL

#######  Add BPM Developer course specific files####
ADD ./resources/integrationTier-domain-1.0.jar $JBOSS_HOME/standalone/deployments/business-central.war/WEB-INF/lib/
