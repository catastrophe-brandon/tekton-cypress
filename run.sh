#!/usr/bin/env bash


echo "Clearing out previous task run (if present)"
yes | tkn taskrun delete e2e-task-run
yes | tkn pipelinerun delete e2e-pipeline-run

set -e

echo "Applying E2E task definition"
kubectl apply --filename e2e_task.yaml

echo "Apply E2E Pipeline"
kubectl apply --filename e2e_pipeline.yaml

echo "Applying E2E PipelineRun"
kubectl apply --filename e2e_pipeline_run.yaml

# View the logs of recent task runs
echo "Waiting for pods to spin up..."
sleep 10

echo "== PipelineRun Logs ==="
tkn pipelinerun logs

