#!/bin/bash

printf "\nAuthenticating to AWS\n"
#aws configure --profile egranger-rhods
export AWS_PROFILE=egranger-rhods
aws sts get-caller-identity | sed 's/^/    /'

printf "\nAuthenticating to OLM with rosa CLI\n"
printf "    https://console.redhat.com/openshift/token/rosa\n"

OCM_ACCOUNT=${OCM_ACCOUNT:-dummy}
AWS_ACCOUNT=${AWS_ACCOUNT:-dummy}
ROSA_CLUSTER_NAME=${ROSA_CLUSTER_NAME:-rosa-demo}
ROSA_CLUSTER_REGION=${ROSA_CLUSTER_REGION:-us-east-2}

printf "\nReview auth info\n"

    rosa whoami | sed 's/^/    /'

printf "\nensure it's in the right accounts\n"

    if rosa whoami | grep  "${OCM_ACCOUNT}" > /dev/null 2>&1 ; then
        printf '    OCM account is ok\n'
    else
        printf '    wrong OCM account\nexiting\n'
        exit
    fi
    if rosa whoami | grep  "${AWS_ACCOUNT}" > /dev/null 2>&1 ; then
        printf '    AWS account is ok\n'
    else
        printf '    wrong AWS account\nexiting\n'
        exit
    fi

printf "\nVerifying quota and oc client\n    "
    rosa verify quota
    printf '    '
    rosa verify openshift-client

# printf "\nDoing the rosa init\n"


printf "\nListing existing clusters\n"
    rosa list cluster | sed 's/^/    /'


printf "\nkicking off deployment unless it's already started\n"

    if rosa list cluster | grep  "${ROSA_CLUSTER_NAME}" > /dev/null 2>&1 ; then
        printf "    Cluster called ${ROSA_CLUSTER_NAME} already found\n"
        printf "    Skipping deployment part\n"
    else
        printf "    Cluster called ${ROSA_CLUSTER_NAME} not found\n"
        printf '    Kicking deployment off\n'
        rosa create cluster \
            --cluster-name ${ROSA_CLUSTER_NAME} \
            --yes \
            --region=${ROSA_CLUSTER_REGION}\
            --compute-machine-type m5.xlarge \
            --compute-nodes 2
    fi

printf "\nWaiting until cluster is fully deployed\n"

    if rosa list cluster | grep  "${ROSA_CLUSTER_NAME}" | grep -i waiting > /dev/null 2>&1 ; then
        printf "\n State: Waiting\n"
        # timeout 10s bash -c -- 'while rosa list cluster | grep  "${ROSA_CLUSTER_NAME}" | grep installing > /dev/null 2>&1; do printf "." ; sleep 1 ;done'
        printf "\nwatching logs\n"
        rosa logs install -c ${ROSA_CLUSTER_NAME} --watch
    else
        printf "\n    waiting is over\n"
    fi

printf "\nWaiting until cluster is fully deployed\n"

    if rosa list cluster | grep  "${ROSA_CLUSTER_NAME}" | grep installing > /dev/null 2>&1 ; then
        printf "\n State: Installing\n"
        # timeout 10s bash -c -- 'while rosa list cluster | grep  "${ROSA_CLUSTER_NAME}" | grep installing > /dev/null 2>&1; do printf "." ; sleep 1 ;done'
        printf "\nwatching logs\n"
        rosa logs install -c ${ROSA_CLUSTER_NAME} --watch
    else
        printf "\n    installing is over\n"
    fi

printf "\nRosa Cluster is now ready\n"

    if rosa list cluster | grep  "${ROSA_CLUSTER_NAME}" | grep -i ready > /dev/null 2>&1 ; then
        printf "\n State: Ready\n"
        # timeout 10s bash -c -- 'while rosa list cluster | grep  "${ROSA_CLUSTER_NAME}" | grep installing > /dev/null 2>&1; do printf "." ; sleep 1 ;done'
    fi

#rosa install addon cluster-logging-operator --cluster=<cluster_name> --interactive

# rosa install addon managed-odh --cluster="${ROSA_CLUSTER_NAME}"
# rosa create machinepool --cluster="${ROSA_CLUSTER_NAME}" --name=mp-1 --replicas=3 --instance-type=m5.xlarge

printf "\nAdding Machine Pool for RHODS\n"

    if rosa list machinepools --cluster=${ROSA_CLUSTER_NAME}  | grep rhods > /dev/null 2>&1 ; then
        printf "\n  Found existing RHODS machine pool.\nSkipping\n"
    else
        printf "\n    Adding a machinepool for RHODS\n"
        rosa create machinepool \
            --cluster="${ROSA_CLUSTER_NAME}" \
            --name=rhods-pool-m5-2xlarge \
            --instance-type=m5.2xlarge \
            --enable-autoscaling   \
            --max-replicas 3 \
            --min-replicas 0 | sed 's/^/    /'
    fi

printf "\nInstalling addon\n"

    rosa list addons --cluster=${ROSA_CLUSTER_NAME} | sed 's/^/    /'

    if rosa list addons --cluster=${ROSA_CLUSTER_NAME}  | grep 'managed-odh' | grep 'not\ installed' > /dev/null 2>&1 ; then
        printf "\n    Installing RHODS addon\n"
        rosa install addon \
            managed-odh --cluster="${ROSA_CLUSTER_NAME}"
    else
        printf "\n    Skipping RHODS addon install\n"
    fi


printf "\nSetting up default admin account\n"

    #use rosa describe admin --cluster=rosa-demo  here
    if rosa list users --cluster=${ROSA_CLUSTER_NAME}  | grep 'admin'  > /dev/null 2>&1 ; then
        printf "\n    Admin account already exists\n"
    else
        printf "\n    Default admin not found.\n    Creating it\n"
        # rosa create admin \
        #    --cluster="${ROSA_CLUSTER_NAME}" \
        #     tee .rosa.admin.txt
    fi

    #cat  .rosa.admin.txt


printf "\nSetting up default IDP\n"

    CONSOLE_URL="$( rosa describe cluster --cluster=$ROSA_CLUSTER_NAME | grep -o 'console\-openshift.*apps\.com'  )"
    API_URL="$( rosa describe cluster --cluster=$ROSA_CLUSTER_NAME | grep -o 'api\..*6443'  )"

    GOOGLE_CLIENT_ID=${GOOGLE_CLIENT_ID:-empty}
    GOOGLE_CLIENT_SECRET=${GOOGLE_CLIENT_SECRET:-empty}



    if rosa list idp --cluster=${ROSA_CLUSTER_NAME}  | grep 'RedHat\-SSO'  > /dev/null 2>&1 ; then
        printf "\n    IDP already added\n"
    else
        printf "\n    Adding IDP\n"
        rosa create idp --type=google \
            --cluster="${ROSA_CLUSTER_NAME}" \
            --name RedHat-SSO \
            --mapping-method claim \
            --client-id "${GOOGLE_CLIENT_ID}" \
            --client-secret "${GOOGLE_CLIENT_SECRET}" \
            --hosted-domain "redhat.com"
    fi

    printf "\n    Displaying Oauth2Callback URL"
    printf "https://$CONSOLE_URL/oauth2callback/RedHat-SSO\n" | sed 's/console\-openshift\-console/oauth-openshift/'

printf "\nGranting cluster-admin\n"

    rosa grant user cluster-admin --user="egranger@redhat.com" --cluster=${ROSA_CLUSTER_NAME}






exit

# timeout 5s bash -c -- 'while true; do printf "." ; ;done'

# rosa describe cluster -c ${ROSA_CLUSTER_NAME}

# timeout 10s bash -c -- 'while rosa list cluster | grep  "${ROSA_CLUSTER_NAME}" | grep installing > /dev/null 2>&1; do printf "\r\033[K ..waiting.." ; sleep 1 ;done'



# z
# exit

