#!/usr/bin/env bash

# Install Tekton and required tasks to execute the pipeline
# TODO: confirm kubectl and tkn are installed and functional
set -e

# Install Tekton to an existing minikube instance
# install tekton
kubectl apply --filename https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml

# This will show `1/1` under the READY column once tekton is available
kubectl get pods --namespace tekton-pipelines --watch

# Install the git-clone task for use in the pipeline
tkn hub install task git-clone