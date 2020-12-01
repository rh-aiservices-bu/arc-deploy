#!/usr/bin/env bash

oc apply -f modh-demo-kafka.yaml
oc wait kafka/modh-demo --for=condition=Ready --timeout=300s
oc apply -f images-topic.yaml
oc apply -f object-detection-topic.yaml
