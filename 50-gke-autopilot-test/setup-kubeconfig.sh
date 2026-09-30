#!/bin/bash
set -euo pipefail

TARGET_PROJECT_ID="${TARGET_PROJECT_ID:-}"
TARGET_CLUSTER="${TARGET_CLUSTER:-}"
TARGET_REGION="${TARGET_REGION:-asia-northeast3}"
TARGET_KUBECONFIG="${TARGET_KUBECONFIG:-$HOME/.kube/config_new-autopilot}"

if [[ -z "$TARGET_PROJECT_ID" || -z "$TARGET_CLUSTER" ]]; then
  echo "Usage: TARGET_PROJECT_ID=<project> TARGET_CLUSTER=<cluster> [TARGET_REGION=asia-northeast3] $0"
  exit 1
fi

mkdir -p "$(dirname "$TARGET_KUBECONFIG")"
touch "$TARGET_KUBECONFIG"
chmod 600 "$TARGET_KUBECONFIG"

export KUBECONFIG="$TARGET_KUBECONFIG"

echo "[1/3] Create/refresh kubeconfig"
gcloud container clusters get-credentials "$TARGET_CLUSTER" \
  --region "$TARGET_REGION" \
  --project "$TARGET_PROJECT_ID"

echo "[2/3] Current context"
kubectl config current-context

echo "[3/3] Cluster endpoint"
kubectl cluster-info

echo
echo "KUBECONFIG=$TARGET_KUBECONFIG"
