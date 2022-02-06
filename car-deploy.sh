#!/bin/bash

## Check pre-reqs

if oc cluster-info > /dev/null 2>&1 ; then
    # executes this block of code,
    # if some_command would result in:  $? -eq 0
    printf "\nConnected to an OpenShift Cluster successfully:\n"
    # printf "        "
    oc cluster-info | sed 's/^/    /' | grep running
    printf "Versions:\n"
    oc version | sed 's/^/    /'
else
    # executes this block of code,
    # if some_command would result in:  $? -ne 0
    printf "\nThe command 'oc cluster-info' does not seem to work. Please fix.\n"
fi


FOO="${VARIABLE:-default}"

GIT_ORG="${GIT_ORG:-"https://github.com/rh-aiservices-bu"}"
GIT_PREFIX="${GIT_PREFIX:-"${GIT_ORG}/car-"}"
GIT_REF="${GIT_REF:-"main"}"

APP_GIT_REPO="${APP_GIT_REPO:-"${GIT_PREFIX}app#${GIT_REF}"}"
REST_GIT_REPO="${REST_GIT_REPO:-"${GIT_PREFIX}rest#${GIT_REF}"}"
KAFKA_GIT_REPO="${KAFKA_GIT_REPO:-"${GIT_PREFIX}kafka#${GIT_REF}"}"
CAR_NS="car-dev"

## Variables with defaults

OBJECT_DETECTION_URL="http://car-rest:8080/predictions"
KAFKA_BOOTSTRAP_SERVER="object-detection-kafka-bootstrap:9092"



##
cat <<EOF | oc apply -f -
apiVersion: v1
kind: Namespace
metadata:
  annotations:
  name: ${CAR_NS}
EOF


# printf "\n\n######## deploy rest service ########\n"

# DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export OBJECT_DETECTION_URL="${OBJECT_DETECTION_URL}"
bash common/deploy.sh

oc -n ${CAR_NS} new-app \
    python:3.8-ubi8~${REST_GIT_REPO} \
    -l 'app.kubernetes.io/component=car-rest' \
    -l 'app.kubernetes.io/instance=car-rest' \
    -l 'app.kubernetes.io/part-of=car' \
    -o yaml > ./new-app-rest.yaml

oc -n ${CAR_NS} apply -f  ./new-app-rest.yaml

# oc expose svc/car-rest

# oc process -f openshift/template.yaml -p PARAM1=VALUE1 -p PARAM2=VALUE2


oc -n ${CAR_NS} new-app \
    nodejs:14-ubi8~${APP_GIT_REPO} \
    -l 'app.kubernetes.io/component=car-app' \
    -l 'app.kubernetes.io/instance=car-app' \
    -l 'app.kubernetes.io/part-of=car' \
    -o yaml > ./new-app-app.yaml

oc -n ${CAR_NS} apply -f  ./new-app-app.yaml


# oc -n ${CAR_NS} create route edge car-app --service=car-app

oc -n ${CAR_NS} create route edge car-app \
    --service=car-app \
    --dry-run=client  -o yaml > route.yaml

oc -n ${CAR_NS} apply -f  ./route.yaml


# # oc -n ${CAR_NS} set env deployment/car-app --from=secret/object-detection-kafka
oc -n ${CAR_NS} set env deployment/car-app --from=configmap/object-detection-rest


# python
#   Project: openshift
#   Tags:    2.7-ubi7, 2.7-ubi8, 3.6-ubi8, 3.8-ubi7, 3.8-ubi8, 3.9-ubi8, latest



# 131  oc get template
#   132  oc get template  -A
#   133  oc get template  -A  | grep python
#   134  oc get template  -A  | grep py
#   136  oc new-app --search --template=ruby --output=yaml
#   137  oc new-app --search --template=python --output=yaml
#   138  oc new-app --search --template=python
#   184  oc get route pipelines-vote-ui --template='http://{{.spec.host}}'
#   186  history | grep template

#     110  oc new-app --help
#   114  oc get new-apps --all-namespaces
#   115  oc get new-app --all-namespaces
#   135  oc new-app --help
#   136  oc new-app --search --template=ruby --output=yaml
#   137  oc new-app --search --template=python --output=yaml
#   138  oc new-app --search --template=python
#   139  oc new-app --search python
#   147  oc new-app --help | grep label
#   154  oc new-app --help | more
#   155  oc new-app --list
#   156  oc new-app --list | grep python
#   157  oc new-app --help | more
#   162  oc new-app --help | more
#   187  oc new-app --search --template=python
#   189  oc new-app --search --template=python

#   oc describe template openjdk18-web-basic-s2i -n openshift

#    oc get templates -n openshift

# $ cat helloworld.params
# ADMIN_USERNAME=admin
# ADMIN_PASSWORD=mypassword
# $ oc new-app ruby-helloworld-sample --param-file=helloworld.params
# $ cat helloworld.params | oc new-app ruby-helloworld-sample --param-file=-