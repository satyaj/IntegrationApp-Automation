#!/usr/bin/env bash

. ./env.sh 

oc new-project $DEV_PROJECT 2> /dev/null
while [ $? \> 0 ]; do
    sleep 1
    printf "."
    oc new-project $DEV_PROJECT 2> /dev/null
done

oc new-app jenkins-persistent

echo "Setup the surrounding softwate and environment"
echo
echo "Start up MySQL for database access"

oc new-app mysql-ephemeral --param=MYSQL_PASSWORD=password --param=MYSQL_USER=dbuser --param=MYSQL_DATABASE=sampledb

echo "Start up Broker"
oc import-image amq-broker-72-openshift:1.3 --from=registry.access.redhat.com/amq-broker-7/amq-broker-72-openshift:1.3-4 --confirm
oc new-app -f projecttemplates/amq-broker-72-basic.yaml --param=AMQ_USER=admin --param=AMQ_PASSWORD=admin --param=IMAGE_STREAM_NAMESPACE=$DEV_PROJECT


echo "import fuse-user-service pipeline"
oc new-app -f fuse-user-service/src/main/resources/pipeline-app-build.yml -p IMAGE_NAMESPACE=$DEV_PROJECT -p DEV_PROJECT=$DEV_PROJECT -p TEST_PROJECT=$TEST_PROJECT -p PROD_PROJECT=$PROD_PROJECT

echo "import maingateway-service pipeline"
oc new-app -f maingateway-service/src/main/resources/pipeline-app-build.yml -p IMAGE_NAMESPACE=$DEV_PROJECT -p DEV_PROJECT=$DEV_PROJECT -p TEST_PROJECT=$TEST_PROJECT -p PROD_PROJECT=$PROD_PROJECT

echo "import nodejsalert-ui pipeline"
oc new-app -f nodejsalert-ui/resources/pipeline-app-build.yml -p IMAGE_NAMESPACE=$DEV_PROJECT -p DEV_PROJECT=$DEV_PROJECT -p TEST_PROJECT=$TEST_PROJECT -p PROD_PROJECT=$PROD_PROJECT

echo "import fuse-alert-service pipeline"
oc new-app -f fuse-alert-service/src/main/resources/pipeline-app-build.yml -p IMAGE_NAMESPACE=$DEV_PROJECT -p DEV_PROJECT=$DEV_PROJECT -p TEST_PROJECT=$TEST_PROJECT -p PROD_PROJECT=$PROD_PROJECT


echo "import integration-master-pipeline"
oc new-app -f pipelinetemplates/pipeline-aggregated-build.yml -p IMAGE_NAMESPACE=$DEV_PROJECT -p DEV_PROJECT=$DEV_PROJECT -p TEST_PROJECT=$TEST_PROJECT -p PROD_PROJECT=$PROD_PROJECT -p PROD_PROJECT=rh-prod -p PRIVATE_BASE_URL=http://maingateway-service-rh-test.app.middleware.ocp.cloud.lab.eng.bos.redhat.com -p PUBLIC_PRODUCTION_WILDCARD_DOMAIN=app.middleware.ocp.cloud.lab.eng.bos.redhat.com -p PUBLIC_STAGING_WILDCARD_DOMAIN=staging.app.middleware.ocp.cloud.lab.eng.bos.redhat.com -p DEVELOPER_ACCOUNT_ID=ahameed@redhat.com


echo "import 3scale API publishing pipeline"
oc new-app -f cicd-3scale/3scaletoolbox/pipeline-template.yaml -p IMAGE_NAMESPACE=$DEV_PROJECT -p DEV_PROJECT=$DEV_PROJECT -p TEST_PROJECT=$TEST_PROJECT -p PROD_PROJECT=$PROD_PROJECT -p PROD_PROJECT=rh-prod -p PRIVATE_BASE_URL=http://maingateway-service-rh-test.app.middleware.ocp.cloud.lab.eng.bos.redhat.com -p PUBLIC_PRODUCTION_WILDCARD_DOMAIN=app.middleware.ocp.cloud.lab.eng.bos.redhat.com -p PUBLIC_STAGING_WILDCARD_DOMAIN=staging.app.middleware.ocp.cloud.lab.eng.bos.redhat.com -p DEVELOPER_ACCOUNT_ID=ahameed@redhat.com

oc new-project $TEST_PROJECT 2> /dev/null
while [ $? \> 0 ]; do
    sleep 1
    printf "."
    oc new-project $TEST_PROJECT 2> /dev/null
done


echo "Setup the surrounding softwate and environment"
echo
echo "Start up MySQL for database access"

oc new-app mysql-ephemeral --param=MYSQL_PASSWORD=password --param=MYSQL_USER=dbuser --param=MYSQL_DATABASE=sampledb

echo "Start up Broker"
oc import-image amq-broker-72-openshift:1.3 --from=registry.access.redhat.com/amq-broker-7/amq-broker-72-openshift:1.3-4 --confirm
oc new-app -f projecttemplates/amq-broker-72-basic.yaml --param=AMQ_USER=admin --param=AMQ_PASSWORD=admin --param=IMAGE_STREAM_NAMESPACE=$TEST_PROJECT

oc policy add-role-to-user edit system:serviceaccount:${DEV_PROJECT}:jenkins -n ${TEST_PROJECT}
oc policy add-role-to-user edit system:serviceaccount:${DEV_PROJECT}:default -n ${TEST_PROJECT}
oc policy add-role-to-user system:image-puller system:serviceaccount:${TEST_PROJECT}:default -n ${DEV_PROJECT}
oc policy add-role-to-user view --serviceaccount=default -n ${DEV_PROJECT}

#this should be used in development/demo environment for testing purpose

oc new-project $PROD_PROJECT 2> /dev/null
while [ $? \> 0 ]; do
    sleep 1
    printf "."
    oc new-project $PROD_PROJECT 2> /dev/null
done


echo "Setup the surrounding softwate and environment"
echo
echo "Start up MySQL for database access"
oc project $PROD_PROJECT
oc new-app mysql-ephemeral --param=MYSQL_PASSWORD=password --param=MYSQL_USER=dbuser --param=MYSQL_DATABASE=sampledb

echo "Start up Broker"
oc import-image amq-broker-72-openshift:1.3 --from=registry.access.redhat.com/amq-broker-7/amq-broker-72-openshift:1.3-4 --confirm
oc new-app -f projecttemplates/amq-broker-72-basic.yaml --param=AMQ_USER=admin --param=AMQ_PASSWORD=admin --param=IMAGE_STREAM_NAMESPACE=$PROD_PROJECT



oc policy add-role-to-user edit system:serviceaccount:${DEV_PROJECT}:jenkins -n ${PROD_PROJECT}
oc policy add-role-to-user edit system:serviceaccount:${DEV_PROJECT}:default -n ${PROD_PROJECT}
oc policy add-role-to-user system:image-puller system:serviceaccount:${PROD_PROJECT}:default -n ${DEV_PROJECT}
oc policy add-role-to-user view --serviceaccount=default -n ${DEV_PROJECT}

oc project $DEV_PROJECT
