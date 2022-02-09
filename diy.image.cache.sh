#!/bin/bash

function generate_ds () {
    local name="$1"
    local ref="$2"
    printf "
---
apiVersion: apps/v1
kind: DaemonSet
namespace: rhods-notebooks
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

printf "   oc apply -n rhods-notebooks -f ./generated/ds_${name}.yaml\n"

}


printf "run these commands if you want to create the daemonsets\n"

for imagename in $( oc -n redhat-ods-applications get \
                    imagestreamtags -l  'opendatahub.io/notebook-image=true' \
                     -o jsonpath="{.items[*].metadata.name}" \
                     ) ; do

    imgname=$(echo "${imagename}" | grep -o '^.*\:' | sed 's/\://' )
    imgref=$(  oc -n redhat-ods-applications get \
                imagestreamtags "${imagename}"  \
                    -o jsonpath="{.image.dockerImageReference}" \
                    )
    # printf "${imgname}\n"
    # printf "${imgref}\n"

    generate_ds "${imgname}"  "${imgref}"

done


exit
