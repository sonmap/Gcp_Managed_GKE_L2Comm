#!/usr/bin/env bash
set -euo pipefail

ADMIN_USER="admin@sonmap.net"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# 10/20/21 are initiated with admin@sonmap.net.
# The Terraform Google providers then impersonate sa-l2comm-tf-admin,
# so administrator credentials are not embedded in Terraform state/config.
export GOOGLE_OAUTH_ACCESS_TOKEN="$(gcloud auth print-access-token --account="${ADMIN_USER}")"

for stage in 10-network 20-platform 21-app; do
  echo "===== APPLY ${stage} ====="
  cd "${ROOT_DIR}/terraform/${stage}"
  terraform init
  terraform fmt -check
  terraform validate
  terraform plan -out=tfplan
  terraform apply tfplan
done

unset GOOGLE_OAUTH_ACCESS_TOKEN
