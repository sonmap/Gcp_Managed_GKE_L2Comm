#!/bin/bash
set -euo pipefail

TARGET_KUBECONFIG="${TARGET_KUBECONFIG:-$HOME/.kube/config_gke-l2comm-batch-an3}"
TARGET_NAMESPACE="${TARGET_NAMESPACE:-nms-prd}"
TARGET_SERVICE_ACCOUNT="${TARGET_SERVICE_ACCOUNT:-nms-prd-sa}"

export KUBECONFIG="$TARGET_KUBECONFIG"

echo "Context: $(kubectl config current-context)"
echo "Namespace: $TARGET_NAMESPACE"
echo "ServiceAccount: $TARGET_SERVICE_ACCOUNT"

if kubectl get namespace "$TARGET_NAMESPACE" >/dev/null 2>&1; then
  echo "Namespace already exists: $TARGET_NAMESPACE"
else
  kubectl create namespace "$TARGET_NAMESPACE"
fi

if kubectl get serviceaccount "$TARGET_SERVICE_ACCOUNT" -n "$TARGET_NAMESPACE" >/dev/null 2>&1; then
  echo "ServiceAccount already exists: $TARGET_SERVICE_ACCOUNT"
else
  kubectl create serviceaccount "$TARGET_SERVICE_ACCOUNT" -n "$TARGET_NAMESPACE"
fi

echo
kubectl get namespace "$TARGET_NAMESPACE"
kubectl get serviceaccount "$TARGET_SERVICE_ACCOUNT" -n "$TARGET_NAMESPACE"
