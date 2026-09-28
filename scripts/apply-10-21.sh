#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# The Google providers in stages 10/20/21 impersonate:
# sa-l2comm-tf-admin@gcp-prod-edp-edge-509423.iam.gserviceaccount.com
# Base ADC on the VM is the attached Compute Engine service account.

for stage in 10-network 20-platform 21-app; do
  echo "===== APPLY ${stage} ====="
  cd "${ROOT_DIR}/terraform/${stage}"
  terraform init
  terraform fmt -check
  terraform validate
  terraform plan -out=tfplan
  terraform apply tfplan
done
