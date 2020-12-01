#!/usr/bin/env bash
oc run images-console-consumer -ti --image=strimzi/kafka:0.20.0-kafka-2.6.0 --rm=true --restart=Never -- bin/kafka-console-consumer.sh --bootstrap-server modh-demo-kafka-bootstrap:9092 --topic images --from-beginning
