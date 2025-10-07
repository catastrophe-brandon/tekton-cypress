#!/usr/bin/env bash


# For whatever reason, minikube has issues pulling the cypress image and some others
# This script explicitly pulls them with podman and then loads them into minikube
#
set -e
podman pull cypress/included:latest
minikube image load cypress/included:latest

# TODO: add code to pull the minikube dashboard images and load them into the cluster

