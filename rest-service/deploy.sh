#!/usr/bin/env bash
printf "\n\n######## deploy rest service ########\n"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

oc new-app python:3.8-ubi8~https://github.com/rh-aiservices-bu/object-detection-rest.git \
-l 'app.kubernetes.io/component=object-detection-rest' \
-l 'app.kubernetes.io/instance=object-detection-rest' \
-l 'app.kubernetes.io/part-of=object-detection-rest'

oc expose svc/object-detection-rest
oc set env deployment/object-detection-app --from=configmap/object-detection-rest