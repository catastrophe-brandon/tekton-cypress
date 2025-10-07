#!/usr/bin/env bash


echo "Clearing out previous task run (if present)"
yes | tkn taskrun delete e2e-task-run

set -e

echo "Applying E2E task definition"
kubectl apply --filename e2e_task.yaml

echo "Apply E2E TaskRun"
kubectl apply --filename e2e_task_run.yaml

# View the logs of recent task runs
echo "Waiting for pods to pull and spin up..."
sleep 10
echo "== TaskRun Logs ==="
tkn taskrun logs

