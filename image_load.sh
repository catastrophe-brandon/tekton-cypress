#!/usr/bin/env bash


# minikube has issues pulling the cypress image and some others due to excessive rate limiting by docker.io
# This script explicitly pulls them with podman and then loads them into minikube to sidestep docker's aggressive limitations
#
set -e

# If you are not logged into quay.io with podman, this will not work
podman pull docker.io/cypress/included:latest
podman push $(podman images cypress -q) quay.io/btweed/cypress
podman pull quay.io/btweed/cypress:latest
minikube image load quay.io/btweed/cypress:latest

# TODO: add code to pull the minikube dashboard images and load them into the cluster

