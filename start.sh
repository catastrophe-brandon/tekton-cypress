#!/usr/bin/env bash

# check status and start minikube if it's not running
minikube start --driver=podman --container-runtime=cri-o

# install tekton
kubectl apply --filename https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml

# This will show `1/1` under the READY column once tekton is available
kubectl get pods --namespace tekton-pipelines --watch
