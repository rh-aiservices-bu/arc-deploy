#!/usr/bin/env bash
printf "\n\n######## deploy app ########\n"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"


oc project ${OC_PROJECT} 2> /dev/null || oc new-project ${OC_PROJECT}
oc project
oc apply -f "${DIR}/app.yaml"


