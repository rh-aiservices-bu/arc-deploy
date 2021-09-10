Object Detection Sample App Setup
=======================

A Sample App that detects dogs

- Kafka instance
- Web application
- Object Detection REST service
- Object Detection Kafka consumer

Prerequesites:
- OpenShift (tested on 4.7)
- Installed Strimzi Operator (tested on 0.23.0)

## Deploying to an OpenShift Cluster

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
REST_SERVICE_GIT_REPO=https://github.com/your-org/object-detection-service.git
KAFKA_CONSUMER_GIT_REPO=https://github.com/your-org/object-detection-kafka-consumer.git
```

#### Execute Deployment
While logged into your cluster, execute the deployment scripts.
```shell script
$ make deploy
```

## Navigate to the Application
Navigate to the URL in the route `object-detection-app`.  To find it, you can query:
```shell
echo "https://$(oc get route object-detection-app -o jsonpath='{.spec.host}')"
```

## Known Issues
- The first request to Tensorflow is slow as it loads up the model.