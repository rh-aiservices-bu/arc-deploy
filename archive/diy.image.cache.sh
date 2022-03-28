#!/bin/bash

printf "\nCreate Namespace \n    "

## Ensure the right namespace exists
cat <<EOF | oc apply -f -
apiVersion: v1
kind: Namespace
metadata:
  annotations:
  name: rhods-prepull-notebooks
EOF

# function that generates yaml files
# 1 daemonset per image
function generate_ds () {
    local name="$1"
    local ref="$2"
    local secretname="$3"
    printf "
---
apiVersion: apps/v1
kind: DaemonSet
namespace: rhods-prepull-notebooks
metadata:
  name: prepull-${name}
spec:
  selector:
    matchLabels:
      name: prepull
  template:
    metadata:
      labels:
        name: prepull
    spec:
      initContainers:
      - name: prepull-${name}
        image: ${ref}
        command: ['start-singleuser.sh', '--help']
      containers:
      - name: pause
        image: gcr.io/google_containers/pause
" > ./generated/ds_${name}.yaml

printf "   oc apply -n rhods-prepull-notebooks -f ./generated/ds_${name}.yaml\n"

}


# without this, images cannot be pulled across namespaces
printf "Creating rolebinding for images\n    "

cat <<EOF | oc -n redhat-ods-applications  apply -f -
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: 'notebook-images-prepuller'
subjects:
  - kind: ServiceAccount
    name: default
    namespace: rhods-prepull-notebooks
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: 'system:image-puller'
EOF


printf "run these commands if you want to create the daemonsets\n"

for imagename in $( oc -n redhat-ods-applications get \
                    imagestreamtags -l  'opendatahub.io/notebook-image=true' \
                     -o jsonpath="{.items[*].metadata.name}" \
                     ) ; do

    #imgname=$(echo "${imagename}" | grep -o '^.*\:' | sed 's/\://' )
    imgname=$(echo "${imagename}" |  sed 's/\:/-/' | sed 's/\./-/g' )
    imgref=$(  oc -n redhat-ods-applications get \
                imagestreamtags "${imagename}"  \
                    -o jsonpath="{.image.dockerImageReference}" \
                    )

    generate_ds "${imgname}"  "${imgref}"

done



