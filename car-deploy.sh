#!/bin/bash

## Check pre-reqs

if oc cluster-info > /dev/null 2>&1 ; then
    # executes this block of code,
    # if some_command would result in:  $? -eq 0
    printf "\nConnected to an OpenShift Cluster successfully:\n"
    # printf "        "
    oc cluster-info | sed 's/^/    /' | grep running
    printf "\nVersions:\n"
    oc version | sed 's/^/    /'
else
    # executes this block of code,
    # if some_command would result in:  $? -ne 0
    printf "\nThe command 'oc cluster-info' does not seem to work. Please fix.\n"
fi

GIT_ORG="${GIT_ORG:-"https://github.com/rh-aiservices-bu"}"
GIT_PREFIX="${GIT_PREFIX:-"${GIT_ORG}/car-"}"
GIT_REF="${GIT_REF:-"main"}"

#APP_GIT_REPO="${APP_GIT_REPO:-"${GIT_PREFIX}app#dev"}"
APP_GIT_REPO="${APP_GIT_REPO:-"${GIT_PREFIX}app#${GIT_REF}"}"
REST_GIT_REPO="${REST_GIT_REPO:-"${GIT_PREFIX}rest#${GIT_REF}"}"
KAFKA_GIT_REPO="${KAFKA_GIT_REPO:-"${GIT_PREFIX}kafka#${GIT_REF}"}"
CAR_NS="${CAR_NS:-"globex-car-main"}"


# APP_GIT_REPO=https://github.com/rh-aiservices-bu/car-app#dev
# KAFKA_GIT_REPO=https://github.com/rh-aiservices-bu/car-kafka#dev
# REST_GIT_REPO=https://github.com/rh-aiservices-bu/car-rest#dev


## Variables with defaults
OBJECT_DETECTION_URL="http://car-rest.${CAR_NS}.svc.cluster.local:8080/predictions"
# KAFKA_BOOTSTRAP_SERVER="object-detection-kafka-bootstrap:9092"

# add .namespace in kafka bootstrap. (car-kafka-bootstrap.car-dev.svc.cluster.local)
# KAFKA_BOOTSTRAP_SERVER="car-kafka-bootstrap:9092"
KAFKA_BOOTSTRAP_SERVER="car-kafka-bootstrap.${CAR_NS}.svc.cluster.local:9092"
KAFKA_SECURITY_PROTOCOL=PLAINTEXT
KAFKA_SASL_MECHANISM=
KAFKA_USERNAME=
KAFKA_PASSWORD=
KAFKA_TOPIC_IMAGES=images
KAFKA_TOPIC_OBJECTS=objects

printf "\nCreate Namespace \n    "

## Ensure the right namespace exists
cat <<EOF | oc apply -f -
apiVersion: v1
kind: Namespace
metadata:
  annotations:
  name: ${CAR_NS}
EOF


# printf "\n\n######## deploy rest service ##"

# DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export OBJECT_DETECTION_URL="${OBJECT_DETECTION_URL}"
# bash common/deploy.sh
PARAMS=''
if [[ -n "${KAFKA_BOOTSTRAP_SERVER}" ]]; then
  PARAMS="${PARAMS} -p KAFKA_BOOTSTRAP_SERVER=${KAFKA_BOOTSTRAP_SERVER}"
fi
if [[ -n "${KAFKA_SECURITY_PROTOCOL}" ]]; then
  PARAMS="${PARAMS} -p KAFKA_SECURITY_PROTOCOL=${KAFKA_SECURITY_PROTOCOL}"
fi
if [[ -n "${KAFKA_SASL_MECHANISM}" ]]; then
  PARAMS="${PARAMS} -p KAFKA_SASL_MECHANISM=${KAFKA_SASL_MECHANISM}"
fi
if [[ -n "${KAFKA_USERNAME}" ]]; then
  PARAMS="${PARAMS} -p KAFKA_USERNAME=${KAFKA_USERNAME}"
fi
if [[ -n "${KAFKA_PASSWORD}" ]]; then
  PARAMS="${PARAMS} -p KAFKA_PASSWORD=${KAFKA_PASSWORD}"
fi
if [[ -n "${KAFKA_TOPIC_IMAGES}" ]]; then
  PARAMS="${PARAMS} -p KAFKA_TOPIC_IMAGES=${KAFKA_TOPIC_IMAGES}"
fi
if [[ -n "${KAFKA_TOPIC_OBJECTS}" ]]; then
  PARAMS="${PARAMS} -p KAFKA_TOPIC_OBJECTS=${KAFKA_TOPIC_OBJECTS}"
fi
if [[ -n "${OBJECT_DETECTION_URL}" ]]; then
  PARAMS="${PARAMS} -p OBJECT_DETECTION_URL=${OBJECT_DETECTION_URL}"
fi

printf "\nEnable Strimzi Operator \n"

oc apply -f ./strimzi.sub.yaml | sed 's/^/    /'


printf "\nCreating Common resources \n"

oc -n ${CAR_NS} process -f "common/common.yaml" ${PARAMS} \
  | oc -n ${CAR_NS} apply -f - | sed 's/^/    /'

# echo ${PARAMS}

printf "\nCreating images builds, deployments and services \n"

printf " # rest \n"
oc -n ${CAR_NS} new-app \
    python:3.8-ubi8~${REST_GIT_REPO} \
    -l 'app.kubernetes.io/component=car-rest' \
    -l 'app.kubernetes.io/instance=car-rest' \
    -l 'app.kubernetes.io/part-of=car' \
    -o yaml > ./generated/new-app-rest.yaml


oc -n ${CAR_NS} apply -f  ./generated/new-app-rest.yaml | sed 's/^/    /'


printf " # app \n"
oc -n ${CAR_NS} new-app \
    nodejs:14-ubi8~${APP_GIT_REPO} \
    -l 'app.kubernetes.io/component=car-app' \
    -l 'app.kubernetes.io/instance=car-app' \
    -l 'app.kubernetes.io/part-of=car' \
    -o yaml > ./generated/new-app-app.yaml

oc -n ${CAR_NS} apply -f \
   ./generated/new-app-app.yaml | sed 's/^/    /'


printf " # kafka instance\n"
oc -n ${CAR_NS} apply \
  -f "kafka/resources/object-detection-kafka.yaml" \
  | sed 's/^/    /'

printf " # kafka-consumer \n"
oc -n ${CAR_NS} new-app python:3.8-ubi8~${KAFKA_GIT_REPO} \
    --name='car-kafka-consumer' \
    -l 'app.kubernetes.io/component=car-kafka-consumer' \
    -l 'app.kubernetes.io/instance=car-kafka-consumer' \
    -l 'app.kubernetes.io/part-of=car' \
    -o yaml > ./generated/new-app-kafka-cons.yaml

oc -n ${CAR_NS} apply -f  ./generated/new-app-kafka-cons.yaml | sed 's/^/    /'

printf "\nWaiting for Kafka pod \n"
oc  -n ${CAR_NS} wait kafka/car \
  --for=condition=Ready --timeout=300s \
  | sed 's/^/    /'

printf "\nCreating Kafka topics \n"
oc -n ${CAR_NS} apply -f "kafka/resources/images-topic.yaml" | sed 's/^/    /'
oc -n ${CAR_NS} apply -f "kafka/resources/objects-topic.yaml" | sed 's/^/    /'

printf "\nApplying env vars \n"
oc -n ${CAR_NS} set env deployment/car-app            --from=configmap/car-rest | sed 's/^/    /'
oc -n ${CAR_NS} set env deployment/car-kafka-consumer --from=secret/car-kafka | sed 's/^/    /'
oc -n ${CAR_NS} set env deployment/car-app            --from=secret/car-kafka | sed 's/^/    /'

printf "\nCreating Route \n"
oc -n ${CAR_NS} create route edge car-app \
    --service=car-app \
    --dry-run=client  -o yaml > generated/route.yaml
oc -n ${CAR_NS} apply -f  ./generated/route.yaml | sed 's/^/    /'

printf "\nRestarting pods \n"
oc -n ${CAR_NS} rollout restart deployment car-app | sed 's/^/    /'
oc -n ${CAR_NS} rollout restart deployment car-kafka-consumer | sed 's/^/    /'


# printf "\n\n######## deploy object detection kafka topics ##"


# oc -n ${CAR_NS} rollout restart deployment car-app
printf "\nURL for this env: \n"
printf "    https://$(oc -n ${CAR_NS} describe route car-app | grep Host | awk '{ print $3 }')/\n\n"

exit


multiple () {
  export APP_GIT_REPO=https://github.com/rh-aiservices-bu/car-app#main
  export KAFKA_GIT_REPO=https://github.com/rh-aiservices-bu/car-kafka#main
  export REST_GIT_REPO=https://github.com/rh-aiservices-bu/car-rest#main
  export CAR_NS='globex-car-main'
  #oc -n globex-dev delete all --all
  bash car-deploy.sh

  export APP_GIT_REPO=https://github.com/rh-aiservices-bu/car-app#main
  export KAFKA_GIT_REPO=https://github.com/rh-aiservices-bu/car-kafka#main
  export REST_GIT_REPO=https://github.com/rh-aiservices-bu/car-rest#main
  export CAR_NS='globex-car-main'
  bash car-deploy.sh

  export APP_GIT_REPO=https://github.com/rh-aiservices-bu/car-app#dev
  export KAFKA_GIT_REPO=https://github.com/rh-aiservices-bu/car-kafka#dev
  export REST_GIT_REPO=https://github.com/rh-aiservices-bu/car-rest#dev
  export CAR_NS='globex-car-dev'
  bash car-deploy.sh

}
