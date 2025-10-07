#!/usr/bin/env bash

# Install Tekton to an existing minikube instance
# install tekton
kubectl apply --filename https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml

# This will show `1/1` under the READY column once tekton is available
kubectl get pods --namespace tekton-pipelines --watch

