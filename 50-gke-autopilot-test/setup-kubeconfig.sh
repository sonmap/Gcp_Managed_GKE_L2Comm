#!/bin/bash
set -euo pipefail

# Source VM project (where this script is executed)
SOURCE_VM_PROJECT="${SOURCE_VM_PROJECT:-gcp-prod-edp-hub-vpchost}"

# Target GKE Autopilot cluster
TARGET_PROJECT_ID="${TARGET_PROJECT_ID:-gcp-prod-edp-edge-509423}"
TARGET_CLUSTER="${TARGET_CLUSTER:-gke-l2comm-batch-an3}"
TARGET_REGION="${TARGET_REGION:-asia-northeast3}"
TARGET_KUBECONFIG="${TARGET_KUBECONFIG:-$HOME/.kube/config_gke-l2comm-batch-an3}"
USE_INTERNAL_IP="${USE_INTERNAL_IP:-0}"

mkdir -p "$(dirname "$TARGET_KUBECONFIG")"
touch "$TARGET_KUBECONFIG"
chmod 600 "$TARGET_KUBECONFIG"

export KUBECONFIG="$TARGET_KUBECONFIG"

echo "SOURCE_VM_PROJECT=$SOURCE_VM_PROJECT"
echo "TARGET_PROJECT_ID=$TARGET_PROJECT_ID"
echo "TARGET_CLUSTER=$TARGET_CLUSTER"
echo "TARGET_REGION=$TARGET_REGION"
echo "TARGET_KUBECONFIG=$TARGET_KUBECONFIG"
echo

echo "[1/3] Create/refresh kubeconfig"
if [[ "$USE_INTERNAL_IP" == "1" ]]; then
  gcloud container clusters get-credentials "$TARGET_CLUSTER" \
    --region "$TARGET_REGION" \
    --project "$TARGET_PROJECT_ID" \
    --internal-ip
else
  gcloud container clusters get-credentials "$TARGET_CLUSTER" \
    --region "$TARGET_REGION" \
    --project "$TARGET_PROJECT_ID"
fi

echo "[2/3] Current context"
kubectl config current-context

echo "[3/3] Cluster endpoint"
kubectl cluster-info

echo
echo "KUBECONFIG=$TARGET_KUBECONFIG"
