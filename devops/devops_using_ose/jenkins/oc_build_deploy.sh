#!/bin/bash

if [ -z "$1" ]; then
    OPENSHIFT_API_URL=https://master00-mwl.opentlc.com:8443
else
    OPENSHIFT_API_URL=$1
fi
if [ -z "$2" ]; then
    PROJECT=rh-jbride-redhat-com-devops-using-ose
else
    PROJECT=$2
fi
if [ -z "$3" ]; then
    BUILD_CONFIG=webapp-qa
else
    BUILD_CONFIG=$3
fi
if [ -z "$4" ]; then
    CLIENT_LOGGING=0
else
    CLIENT_LOGGING=$4
fi
AUTH_TOKEN=`cat /var/run/secrets/kubernetes.io/serviceaccount/token`

echo -en "oc_build_deploy.sh:  arguments:\n\tOPENSHIFT_API_URL = $OPENSHIFT_API_URL\n\tPROJECT = $PROJECT\n\tBUILD_CONFIG = $BUILD_CONFIG\n\tAUTH_TOKEN = $AUTH_TOKEN\n\tCLIENT_LOGGING=$CLIENT_LOGGING"

subcommand="-n $PROJECT --token=$AUTH_TOKEN --server=$OPENSHIFT_API_URL --certificate-authority=/run/secrets/kubernetes.io/serviceaccount/ca.crt --v=$CLIENT_LOGGING"

# 1)  Kick off build
buildCommand="oc $subcommand start-build ${BUILD_CONFIG}"
echo -en "\nTriggering new application build using the following command:\n$buildCommand\n"
BUILD_ID=`oc $subcommand start-build ${BUILD_CONFIG}`
if [ $? != 0 ];
then
    exit 1;
fi

# 2)  Check that build has succeeded
checkCommand="oc $subcommand get build ${BUILD_ID} -t '{{.status.phase}}'"
echo -en "\nChecking build result status using the following command:\n$checkCommand\n"
rc=1
count=0
attempts=50
while [ $rc -ne 0 -a $count -lt $attempts ]; do
  status=`oc $subcommand get build ${BUILD_ID} -t '{{.status.phase}}'`
  if [[ $status == "Failed" || $status == "Error" || $status == "Canceled" ]]; then
    echo "Fail: Build completed with unsuccessful status: ${status}"
    exit 1
  fi

  if [ $status == "Complete" ]; then
    echo "Build completed successfully!"
    rc=0
  else
    count=$(($count+1))
    echo "Attempt $count/$attempts"
    sleep 5
  fi
done

if [ $rc -ne 0 ]; then
    echo "Fail: Build did not complete in a reasonable period of time"
    exit 1
fi
