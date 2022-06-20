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

# GIT_ORG="${GIT_ORG:-"https://github.com/rh-aiservices-bu"}"
# GIT_PREFIX="${GIT_PREFIX:-"${GIT_ORG}/arc-"}"
# GIT_REF="${GIT_REF:-"main"}"

ARC_PROJ="${1:-"not-a-project"}"
# echo ${ARC_PROJ}

if [[ "${ARC_PROJ}" = "not-a-project" ]]; then
    printf "You did not specify a project.\n"
    printf "Execute the script like such:\n"
    printf "    bash arc-deploy.sh <project_name>\n\n"
    exit
fi

if [[ "${ARC_PROJ}" == *"openshift"* ]]; then
    printf "Your project can not have 'openshift' as part of its name\n"
    exit
fi


if oc get project | grep ${ARC_PROJ} > /dev/null 2>&1; then
    printf "Project ${ARC_PROJ} already exists\n"
else
    printf "Project ${ARC_PROJ} does not exist\n"
    printf "Creating it:\n"
    oc new-project ${ARC_PROJ}

    if [ $? -eq 0 ]
    then
        printf "Creation successful\n"
    else
        printf "Creation failed\n"
        exit
    fi
fi

# ## Argocd Instance
printf "Deploy private instance of ArgoCD\n"
oc -n $ARC_PROJ apply \
    -k "./argocd-instance/" | sed 's/^/    /'

printf "wait for argocd route\n"
timeout 10s bash -c -- "until oc -n ${ARC_PROJ} get routes \
    | grep  'argocd-instance'  > /dev/null 2>&1; do printf '.' ; sleep 1 ;done"

function deploy_and_patch () {
    printf "\nDeploy the apps\n"
    oc -n ${ARC_PROJ} apply \
        -k "/argocd-apps/" | sed 's/^/    /'

    printf "Patch them to add the namespace\n"
    for app in $(oc -n ${ARC_PROJ} get applications --no-headers |  awk '{ print $1 }') ; do
       printf "    patching ${app}\n"
       oc -n ${ARC_PROJ} patch application ${app}  \
       --type='json' \
       -p="[{'op': 'replace', 'path': '/spec/destination/namespace', 'value':'$ARC_PROJ'}]" \
       | sed 's/^/    /'
    done
}

deploy_and_patch

argo_url=$(oc -n ${ARC_PROJ} describe route | grep 'argocd-instance' | grep Host | awk '{ print $3 }' )
printf "\n\nThis is the URL of your ArgoCD instance\n"
printf "    https://${argo_url}/\n\n"
printf "You can open it in your browser to watch the progress of your apps.\n\n"


printf "Waiting (up to 10 minutes) for gogs to deploy fully\n"
timeout 600s bash -c -- "until oc -n ${ARC_PROJ} get pods \
    | grep 'gogs-initialize' \
    | grep  'Completed'  > /dev/null 2>&1; do printf '.' ; sleep 1 ;done"

deploy_and_patch

# timeout 30s bash -c -- "while oc -n ${ARC_PROJ} get applications \
#     | grep  Unknown  > /dev/null 2>&1; do oc -n ${ARC_PROJ} get applications ; sleep 5 ;done"

gogs_url=$(oc -n ${ARC_PROJ} describe route | grep 'gogs' | grep Host | awk '{ print $3 }' )
 #printf "https://$(oc -n \${ARC_PROJ} describe route | grep Host | awk '{ print $3 }')/\n\n"
printf "\n\nThis is the URL of your gogs instance\n"
printf "    https://${gogs_url}/\n"
printf "    User:     gogs \n    Password: gogs\n\n"
printf "This is the URL of your ArgoCD instance\n"
printf "    https://${argo_url}/\n\n"


printf "Other URLs:\n"
for host in $(oc -n ${ARC_PROJ} describe route \
    | grep -E 'frontend|model' \
    |  grep Host \
    | awk '{ print $3 }') ; do
   #echo " ${host}"
    printf "   -  https://"${host}"/\n"
done
printf "\n"

printf "Waiting (up to 10 minutes) for all apps to be done syncing\n"
timeout 600s bash -c -- "while oc -n ${ARC_PROJ} get applications \
    | grep -E 'Progressing|Unknown|Missing|OutOfSync'  > /dev/null 2>&1; do printf '.' ; sleep 5 ;done"

printf "\n"

function printallURLs () {
    printf "All URLs:\n"
    for host in $(oc -n ${ARC_PROJ} describe route \
        |  grep Host \
        | awk '{ print $3 }') ; do
    #echo " ${host}"
        printf "   -  https://"${host}"/\n"
    done
    printf "\n"

}

printallURLs
