#!/usr/bin/env bash
oc run kafka-producer -ti --image=strimzi/kafka:0.20.0-kafka-2.6.0 --rm=true --restart=Never -- bin/kafka-console-producer.sh --broker-list modh-demo-kafka-bootstrap:9092 --topic images

