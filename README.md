# arc deployment

Augmented Reality Coupons (ARC) is an example of an intelligent app deployed on OpenShift.

This repo contains the code needed to get it running in your OpenShift environment (inside of a single namespace)


## basics

* Create a project. If you are in the sandbox, you can't create a new project and will have to work within your existing project.


```bash
oc new-project arc-main
oc new-project arc-dev

export GIT_REF=main
bash arc-deploy.sh arc-main

export GIT_REF=dev
bash arc-deploy.sh arc-dev

```
