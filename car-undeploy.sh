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

CAR_NS="car-dev"

# printf "\n\n######## deploy rest service ########\n"

# DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"



oc -n ${CAR_NS} \
    delete all \
    -l app=car-rest

oc -n ${CAR_NS} \
    delete all \
    -l app=car-app

