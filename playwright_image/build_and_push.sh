#!/usr/bin/env bash

set -e 

podman build . -t playwright-e2e:latest
podman push localhost/playwright-e2e "quay.io/$QUAY_USER/playwright_e2e"

