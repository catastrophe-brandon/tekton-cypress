#!/usr/bin/env bash

# check status and start minikube if it's not running
# More disk space needed for running e2e tests, Tekton, etc.
minikube start --driver=podman --container-runtime=cri-o --disk-size=40g

minikube status
