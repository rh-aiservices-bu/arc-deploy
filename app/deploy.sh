#!/usr/bin/env bash
printf "\n\n######## deploy app ########\n"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"


oc project ${OC_PROJECT} 2> /dev/null || oc new-project ${OC_PROJECT}
oc project

oc new-app --docker-image=quay.io/cfchase/object-detection-app:latest \
-l 'app.kubernetes.io/component=object-detection-app' \
-l 'app.kubernetes.io/instance=object-detection-app' \
-l 'app.kubernetes.io/part-of=object-detection-app'

oc create route edge object-detection-app --service=object-detection-app
oc set env deployment/object-detection-app --from=secret/object-detection-kafka
oc set env deployment/object-detection-app --from=configmap/object-detection-rest
