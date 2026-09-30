#!/bin/bash
set -euo pipefail

TARGET_KUBECONFIG="${TARGET_KUBECONFIG:-$HOME/.kube/config_new-autopilot}"
TARGET_NAMESPACE="${TARGET_NAMESPACE:-nms-prd}"

export KUBECONFIG="$TARGET_KUBECONFIG"

echo "== Context =="
kubectl config current-context

echo
echo "== Namespace =="
kubectl get namespace "$TARGET_NAMESPACE"

echo
echo "== Kubernetes permissions =="
for check in \
  "create pods" \
  "get pods" \
  "delete pods" \
  "create persistentvolumeclaims" \
  "get persistentvolumeclaims" \
  "delete persistentvolumeclaims"
do
  verb="${check%% *}"
  resource="${check#* }"
  printf '%-45s : ' "$verb $resource -n $TARGET_NAMESPACE"
  kubectl auth can-i "$verb" "$resource" -n "$TARGET_NAMESPACE"
done

for check in \
  "create persistentvolumes" \
  "get persistentvolumes" \
  "delete persistentvolumes"
do
  verb="${check%% *}"
  resource="${check#* }"
  printf '%-45s : ' "$verb $resource"
  kubectl auth can-i "$verb" "$resource"
done

echo
echo "== ServiceAccount =="
kubectl get serviceaccount nms-prd-sa -n "$TARGET_NAMESPACE"

echo
echo "Precheck completed."
