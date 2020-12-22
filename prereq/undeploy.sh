#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

oc delete -f "${DIR}/config-map.yaml"
oc delete -f "${DIR}/kafka/images-topic.yaml"
oc delete -f "${DIR}/kafka/objects-topic.yaml"
oc delete -f "${DIR}/kafka/object-detection-kafka.yaml"
