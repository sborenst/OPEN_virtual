#!/bin/bash


echo "Total number of arguments: $#"
echo "Argument 1: $1"
echo "Argument 2: $2"
echo "Argument 3: $3"
echo "Argument 4: $4"
echo "Argument 5: $5"

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
AUTH_TOKEN=`cat /var/run/secrets/kubernetes.io/serviceaccount/token`

echo -en "oc_build_deploy.sh:  arguments:\n\tOPENSHIFT_API_URL = $OPENSHIFT_API_URL\n\tPROJECT = $PROJECT\n\tBUILD_CONFIG = $BUILD_CONFIG\n\tAUTH_TOKEN = $AUTH_TOKEN\n"

alias oc="oc -n $PROJECT --token=$AUTH_TOKEN --server=$OPENSHIFT_API_URL --certificate-authority=/run/secrets/kubernetes.io/serviceaccount/ca.crt --v=10"

# 2)  Kick off build
echo "Triggering new application build and deployment:"
BUILD_ID=`oc start-build ${BUILD_CONFIG}`
if [ $? != 0 ];
then
    exit 1;
fi

# 3) Stream the logs for the build that just started
rc=1
count=0
attempts=3
set +e
while [ $rc -ne 0 -a $count -lt $attempts ]; do
  oc build-logs $BUILD_ID
  rc=$?
  count=$(($count+1))
done
set -e

# 4)  Check that build has succeeded
echo "Checking build result status"
rc=1
count=0
attempts=50
while [ $rc -ne 0 -a $count -lt $attempts ]; do
  status=`oc get build ${BUILD_ID} -t '{{.status.phase}}'`
  if [[ $status == "Failed" || $status == "Error" || $status == "Canceled" ]]; then
    echo "Fail: Build completed with unsuccessful status: ${status}"
    exit 1
  fi

  if [ $status == "Complete" ]; then
    echo "Build completed successfully, will test deployment next"
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
