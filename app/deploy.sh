#!/usr/bin/env bash
printf "\n\n######## deploy app ########\n"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

oc new-app nodejs:14-ubi8~https://github.com/rh-aiservices-bu/object-detection-app.git \
-l 'app.kubernetes.io/component=object-detection-app' \
-l 'app.kubernetes.io/instance=object-detection-app' \
-l 'app.kubernetes.io/part-of=object-detection-app'

oc create route edge object-detection-app --service=object-detection-app
oc set env deployment/object-detection-app --from=secret/object-detection-kafka
oc set env deployment/object-detection-app --from=configmap/object-detection-rest
