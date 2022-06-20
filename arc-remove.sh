#!/bin/bash



if oc cluster-info > /dev/null 2>&1 ; then
    # executes this block of code,
    # if some_command would result in:  $? -eq 0
    printf "Connected to an OpenShift Cluster successfully:\n"
    # printf "        "
    oc cluster-info | sed 's/^/    /' | grep running
    printf "Versions:\n"
    oc version | sed 's/^/    /'
else
    # executes this block of code,
    # if some_command would result in:  $? -ne 0
    printf "The command 'oc cluster-info' does not seem to work. Please fix.\n"
    oc cluster-info
    exit
fi

ARC_PROJ="${1:-"not-a-project"}"

if [[ "${ARC_PROJ}" = "not-a-project" ]]; then
    printf "You did not specify a project.\n"
    printf "Execute the script like such:\n"
    printf "    bash arc-remove.sh <project_name>\n\n"
    exit
fi

if [[ "${ARC_PROJ}" == *"openshift"* ]]; then
    printf "Your project can not have 'openshift' as part of its name\n"
    exit
fi


printf "Deleting applications from the namespace\n"
for app in $(oc -n ${ARC_PROJ} get applications --no-headers |  awk '{ print $1 }') ; do
    echo "patching ${app} with finalizer"
    oc -n ${ARC_PROJ} patch application ${app}  \
        --type='json' \
        -p '{"metadata": {"finalizers": ["resources-finalizer.argocd.argoproj.io"]}}' \
        --type merge

    echo "deleting ${app} with cascade"
    oc -n ${ARC_PROJ} \
        delete applications ${app}
done

printf "Remove instance of ArgoCD\n"
oc -n $ARC_PROJ delete \
    -k "./argocd-instance/" | sed 's/^/    /'
