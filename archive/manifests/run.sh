#!/bin/bash

oc delete namespace argotest01

cat <<EOF | oc apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: argotest01
EOF


oc -n argotest01 apply -k .

route_url="https://$(oc -n argotest01 get routes -o json | jq -r '.items[0].spec.host')/"

echo "curling $route_url"

curl ${route_url}
