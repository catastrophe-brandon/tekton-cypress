#!/usr/bin/env bash


# Clear out any previous task runs
echo "Clearing out previous task run garbage"
yes | tkn taskrun delete e2e-task-run

set -e

kubectl apply --filename e2e_task.yaml
kubectl apply --filename e2e_task_run.yaml

# View the logs of recent task runs
sleep 3
echo "== TaskRun Logs ==="
tkn taskrun logs

