#!/usr/bin/env bash
printf "\n\n######## undeploy rest service ########\n"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

oc delete all -l app=object-detection-rest