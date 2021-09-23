#!/usr/bin/env bash
printf "\n\n######## deploy kafka consumer ########\n"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

oc new-app python:3.8-ubi8~${KAFKA_CONSUMER_GIT_REPO} \
-l 'app.kubernetes.io/component=object-detection-kafka-consumer' \
-l 'app.kubernetes.io/instance=object-detection-kafka-consumer' \
-l 'app.kubernetes.io/part-of=object-detection-kafka-consumer'

oc set env deployment/object-detection-kafka-consumer --from=secret/object-detection-kafka
