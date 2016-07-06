#!/bin/bash

#   EXAMPLES: 
#     /home/opentlc-mgr/bin/provision-ose-projects.sh -a --user=stauilrh --course=BPMS               		:   Creates new BPM project for user: stauilrh
#     /home/opentlc-mgr/bin/provision-ose-projects.sh -r --user=stauilrh --course=BPMS               		:   Removes BPM project for user:  stauilrh
#     /home/opentlc-mgr/bin/provision-ose-projects.sh -a --user=jbride-redhat.com --course=AMQ       		:   Creates new AMQ project for user: jbride-redhat.com
#     /home/opentlc-mgr/bin/provision-ose-projects.sh -a --user=jbride-redhat.com --course=OSE_APPDEV     	:   Creates new App Dev Using OSE project for user: jbride-redhat.com
#     /home/opentlc-mgr/bin/provision-ose-projects.sh -a --user=sjayanti-redhat.com --course=FIS     		:   Creates new Fuse Integration Services project for user: sjayanti-redhat.com

#   ADMIN NOTES:
#   This script is installed at:  opentlc-mgr@inf00-mwl.opentlc.com:/home/opentlc-mgr/bin/provision-ose-projects.sh
#   It is invoked by CloudForms.  The CloudForms log file can be viewed as followed:
#       1)  ssh <userId>@labs.opentlc.com
#       2)  tail -n 50 /var/www/miq/vmdb/log/automation.log
#
#   Client that invokes this script is in CloudForms ruby code written by Patrick
#   A new CloudForms "class" can be created via the following:  Automate -> Datastore -> OPEN -> OSELAB3 -> Class

PATH_TO_OPENTLC_OSE3=/opt/OPEN_virtual/MW-OSE3
OSE_APPDEV=OSE_APPDEV
AMQ=AMQ
BPMS=BPMS
FIS=FIS
JDV_DEV=JDV_DEV
LOG_FILE=/tmp/ose_provision.log

declare -A COURSES
COURSES=(["OSE_APPDEV"]=1 ["BPMS"]=2 ["JDV_DEV"]=2 ["AMQ"]=1 ["FIS"]=0)

ADD=false
REMOVE=false
COURSE_EXIST=false
OPTS=`getopt -o ar -l user:,course: -n 'parse-options' -- "$@"`
if [ $? != 0 ];
then
    echo "Failed parsing options." >&2;
    exit 1;
fi

eval set -- "$OPTS"

while true; do
    case "$1" in
        -a) ADD=true; shift;;
        -r) REMOVE=true; shift;;
        --user) USERNAME="$2"; shift 2;;
        --course) COURSENAME="$2"; shift 2;;
        --) shift; break;;
        *) break;;
    esac
done


verify_course() {
    for course in "${!COURSES[@]}"; do
        if [ "$COURSENAME" == "$course" ] ; then
            echo -en "\nverify_course() coursename = $COURSENAME exists!\n" >> $LOG_FILE;
            COURSE_EXIST=true
        fi
    done

    if [ $COURSE_EXIST = false ] ; then
        echo "The course $COURSENAME is not valid. Possible options are: ${!COURSES[@]} >> $LOG_FILE"
        exit 1
    fi

}

determine_project_name() {

    # prune username of "*.com" suffix
    # username_short="${USERNAME%.*}"

    # replace all dots by dash
    username_short=$(echo $USERNAME | sed -e 's/\./-/g')
    
    echo -en "determine_project_name() username_short = $username_short \n" >> $LOG_FILE;
    PROJECTNAME=$(echo $username_short-$COURSENAME | cut -c -63 | sed s/_/-/g | awk '{print tolower($0)}')
}

pvc_provision() {
    for ((a=1; a <= ${COURSES["$COURSENAME"]} ; a++))
    do
        cat $PATH_TO_OPENTLC_OSE3/persistent-volume-claim.json | sed 's/\("name": "\)[^"]*\("\)/\1claim'$a'\2/g' >> $PROJECTNAME-temp-pvc-claim.json
        oc create -f $PROJECTNAME-temp-pvc-claim.json -n $PROJECTNAME
        rm -f $PROJECTNAME-temp-pvc-claim.json
    done
    echo "$COURSENAME: Number of pvc: ${COURSES["$COURSENAME"]}" >> $LOG_FILE
}

project_provision() {
    oadm new-project $PROJECTNAME --display-name=$PROJECTNAME --description="GPE Project" --admin=$USERNAME
    oadm policy add-role-to-user admin $USERNAME -n $PROJECTNAME
}

app_provision() {
    echo -en "app_provision() coursename = $COURSENAME\n" >> $LOG_FILE;
    if [ "$COURSENAME" = "$BPMS" ] ; then
        # BPM templates (mysql and bpms) include the PVC .... so no need to claim here
        oc new-app --template=gpe-bpm-mysql-template -p DATABASE_SERVICE_NAME=gpe-bpm-mysql -n $PROJECTNAME
        sleep 60;
        oc new-app --template=gpe-bpm-biz-logic-dev-template -p APPLICATION_NAME=gpe-bpms -p DATABASE_SERVICE_NAME=gpe-bpm-mysql -n $PROJECTNAME
    elif [ "$COURSENAME" = "$JDV_DEV" ] ; then
        oc new-app --template=gpe-jdv-pgsql-template -p DATABASE_SERVICE_NAME=gpe-jdv-pgsql -n $PROJECTNAME
    elif [ "$COURSENAME" = "OSE_APPDEV" ] ; then
        # No need to instantiate an app
        # Instead, provide persistence volume claim
        pvc_provision
    elif [ "$COURSENAME" = "FIS" ] ; then
        # No need to instantiate an app
	sleep 0;
    elif [ "$COURSENAME" = "$AMQ" ] ; then

        # last updated from:  tag = ose-v1.3.0-1  ;      project = https://github.com/jboss-openshift/application-templates.git
        oc create -f $PATH_TO_OPENTLC_OSE3/secrets/amq-app-secret.json -n $PROJECTNAME

        # create a PVC called: broker-amq-claim 
        cat $PATH_TO_OPENTLC_OSE3/persistent-volume-claim.json | sed 's/claim1/broker-amq-claim/g' >> $PROJECTNAME-temp-pvc-claim.json
        oc create -f $PROJECTNAME-temp-pvc-claim.json -n $PROJECTNAME >> $LOG_FILE
        rm -f $PROJECTNAME-temp-pvc-claim.json
  
        # create the route to the project to expose tcp ssl 
        cat $PATH_TO_OPENTLC_OSE3/amq-route.yaml | sed 's/projectname/'$PROJECTNAME'/g' >> $PROJECTNAME-temp-route.yaml
        oc create -f $PROJECTNAME-temp-route.yaml -n $PROJECTNAME >> $LOG_FILE
        rm -f $PROJECTNAME-temp-route.yaml
 
        oc new-app --template=amq62-persistent-ssl -p MQ_USERNAME=$USERNAME -p MQ_PASSWORD=redhat -p MQ_QUEUES=exampleQueue -p AMQ_TRUSTSTORE_PASSWORD=password -p AMQ_KEYSTORE_PASSWORD=password -n $PROJECTNAME >> $LOG_FILE
        OUT=$?
        if [ $OUT -ne 0 ];
        then
            # https://github.com/redhat-gpe/fuse_messaging/issues/104
            echo "*** Error provisioning AMQ= $OUT " >> $LOG_FILE
            exit 0;
        fi
    else
        echo "The course $COURSENAME is not valid. Possible options are: ${!COURSES[@]}" >> $LOG_FILE
        exit 1
    fi
}


echo -en "\n`date`" >> $LOG_FILE
verify_course
determine_project_name
if [ "$ADD" = true ] ; then
    echo "Creating project: $PROJECTNAME ;  USERNAME= $USERNAME" >> $LOG_FILE
    project_provision
    app_provision
elif $REMOVE ; then
    echo "Removing project: $PROJECTNAME for $USERNAME" >> $LOG_FILE
    oc delete pvc --all -n $PROJECTNAME >> $LOG_FILE
    oc delete project $PROJECTNAME >> $LOG_FILE
fi
