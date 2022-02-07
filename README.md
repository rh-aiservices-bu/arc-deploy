# CAR deployment

Coupons Augmented Reality is a 3-part app deployed on OpenShift.

This repo contains the code needed to get it running in your OpenShift environment

## Requirements

* OpenShift (tested on 4.9)
* Strimzi Operator (maybe)
* Ability to create a Namespace
* `oc` cli connected to your cluster
* bash prompt

## Variables you can change

```
GIT_ORG="https://github.com/rh-aiservices-bu"
GIT_PREFIX="${GIT_ORG}/car-"
GIT_REF="main"
APP_GIT_REPO="${GIT_PREFIX}app#{GIT_REF}"
REST_GIT_REPO="${GIT_PREFIX}rest#{GIT_REF}"
KAFKA_GIT_REPO="${GIT_PREFIX}kafka#{GIT_REF}"
```

## Variables with defaults

```
OBJECT_DETECTION_URL=http://car-rest:8080/predictions
KAFKA_BOOTSTRAP_SERVER=car-kafka-bootstrap:9092
```


goals:
* deploy it all with a single shell script - first.
* write one app in such a way that it can deployed with oc process or with argo
*

Inputs:
 * URL/ref for 3 distinct git repos
 * namespace


* ./manifests/
*    -.yaml
*  argoCD  deployment
   *  4 input: ns + 3 git repos.
*  tekton


<!-- =======================

A Sample App that detects objects

- Kafka instance
- Web application
- Object Detection REST service
- Object Detection Kafka consumer

Prerequesites:
- OpenShift (tested on 4.7)
- Installed Strimzi Operator (tested on 0.23.0)

## Make commands:
- `make login` - Logs into a cluster and creates/sets project if desired.

Deploy:
- `make deploy` - Equivalent to `make deploy-kafka deploy-common deploy-app deploy-rest-service deploy-kafka-consumer`.  Does not log in.
- `make deploy-kafka` - Deploys kafka instance and topics if Strimzi operator is installed.
- `make deploy-common` - Deploys secrets and configmaps for use in the deployments.
- `make deploy-app` - Deploys front end application to display results on photos  or streams.
- `make deploy-rest-service` - Deploys object detection rest service for single images.
- `make deploy-kafka-consumer` - Deploys object detection kafka consumer for a stream of images.

Undeploy:
- `make undeploy` - Equivalent to `make undeploy-kafka undeploy-common undeploy-app deploy-rest-service deploy-kafka-consumer`.  Does not log in.
- `make undeploy-kafka` - Deletes kafka instance and topics.
- `make undeploy-common` - Deletes secrets and configmaps.
- `make undeploy-app` - Deletes front end application .
- `make undeploy-rest-service` - Deletes object detection rest service..
- `make undeploy-kafka-consumer` - Deletes object detection kafka consumer.

## Basic Full Deployment

#### Log in to your cluster and set your project
```shell
$ oc login --token=sha256~_mytoken --server=https://api.mycluster.com:6443
Logged into "https://api.mycluster.com:6443" as "user" using the token provided.
$ oc new-project object-detection-demo
```
**Alternatively**, you can add login information to your `.env.local` and execute it as part of your scripts

Customize the `.env.local` file to include OpenShift login information
```.dotenv
# using token
OC_URL=https://api.cluster:6443
OC_TOKEN=sha256~blahblah
OC_PROJECT=your-project
```
or
```.dotenv
# using username & password
OC_URL=https://api.cluster:6443
OC_USER=your-username
OC_PASSWORD=your-password
OC_PROJECT=your-project
```

Test with:
```shell script
$ make login
```


#### Using your Fork
If you forked the service/consumer repos, you can edit the `.env.local` to build from your own [source to image](https://github.com/openshift/source-to-image) repository.
```.dotenv
REST_SERVICE_GIT_REPO=https://github.com/your-org/object-detection-rest.git
KAFKA_CONSUMER_GIT_REPO=https://github.com/your-org/object-detection-kafka-consumer.git
```

#### Execute Deployment
While logged into your cluster, execute the deployment scripts.  This will enter
```shell script
$ make deploy
```

### Navigate to the Application
Navigate to the URL in the route `object-detection-app`.  To find it, you can query:
```shell
echo "https://$(oc get route object-detection-app -o jsonpath='{.spec.host}')"
```

## SaaS Kafka Deployment Example
If, for example you did not want to deploy the on cluster Kafka instance, you can deploy the demo without the Strimzi Kafka instance

### Create Kafka Instance, Topics, and Credentials
For example using [Red Hat OpenShift Streams for Apache Kafka](https://console.redhat.com/application-services/streams/kafkas)

- Create a [service account](https://console.redhat.com/beta/application-services/streams/service-accounts) and note the `Client ID` and `Client Secret` for later use
- Create a new [Kafka Instance](https://console.redhat.com/beta/application-services/streams/kafkas) and note the `bootstrap server` and note for later use.
- From the details of the instance, create the topics `images` and `objects`.  If you modify the topic names, you must set those variables later.


### Set the variables in the .env.local file
```.dotenv
# .env.local
KAFKA_BOOTSTRAP_SERVER=<Bootstrap Server>
KAFKA_SECURITY_PROTOCOL=SASL_SSL
KAFKA_SASL_MECHANISM=PLAIN
KAFKA_USERNAME=<Client ID>
KAFKA_PASSWORD=<Client Secret>
KAFKA_TOPIC_IMAGES=images
KAFKA_TOPIC_OBJECTS=objects
```

### Deploy the necessary components
```shell
$ make deploy-common deploy-app deploy-kafka-consumer deploy-rest-service
```


## Known Issues
- The first request to Tensorflow is slow as it loads up the model. -->
