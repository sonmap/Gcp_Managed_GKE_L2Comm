#!/usr/bin/env bash
set -euo pipefail

ADMIN_USER="admin@sonmap.net"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Terraform normally discovers the VM metadata service account first.
# For bootstrap only, force Terraform to use a short-lived access token
# from the explicitly authenticated admin account.
export GOOGLE_OAUTH_ACCESS_TOKEN="$(gcloud auth print-access-token --account="${ADMIN_USER}")"

cd "${ROOT_DIR}/terraform/00-bootstrap"
terraform init
terraform fmt -check
terraform validate
terraform plan -out=tfplan
terraform apply tfplan

unset GOOGLE_OAUTH_ACCESS_TOKEN
