# 1)  Authenticate oc client with OSE Master API
if [ -z &quot;$AUTH_TOKEN&quot; ]; then
  AUTH_TOKEN=`cat /var/run/secrets/kubernetes.io/serviceaccount/token`
fi

if [ -e /run/secrets/kubernetes.io/serviceaccount/ca.crt ]; then
  alias oc=&quot;oc -n $PROJECT --token=$AUTH_TOKEN --server=$OPENSHIFT_API_URL --certificate-authority=/run/secrets/kubernetes.io/serviceaccount/ca.crt &quot;
else
  alias oc=&quot;oc -n $PROJECT --token=$AUTH_TOKEN --server=$OPENSHIFT_API_URL --insecure-skip-tls-verify &quot;
fi

# 2)  Kick off build
echo &quot;Triggering new application build and deployment&quot;
BUILD_ID=`oc start-build ${BUILD_CONFIG}`

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
echo &quot;Checking build result status&quot;
rc=1
count=0
attempts=50
while [ $rc -ne 0 -a $count -lt $attempts ]; do
  status=`oc get build ${BUILD_ID} -t &apos;{{.status.phase}}&apos;`
  if [[ $status == &quot;Failed&quot; || $status == &quot;Error&quot; || $status == &quot;Canceled&quot; ]]; then
    echo &quot;Fail: Build completed with unsuccessful status: ${status}&quot;
    exit 1
  fi

  if [ $status == &quot;Complete&quot; ]; then
    echo &quot;Build completed successfully, will test deployment next&quot;
    rc=0
  else
    count=$(($count+1))
    echo &quot;Attempt $count/$attempts&quot;
    sleep 5
  fi
done

if [ $rc -ne 0 ]; then
    echo &quot;Fail: Build did not complete in a reasonable period of time&quot;
    exit 1
fi
