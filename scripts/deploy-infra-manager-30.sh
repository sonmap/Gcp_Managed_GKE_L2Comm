#!/usr/bin/env bash
set -euo pipefail

PROJECT_ID="gcp-prod-edp-edge-509423"
REGION="asia-northeast3"
DEPLOYMENT_ID="l2comm-batch-30"
INFRA_SA="sa-l2comm-inframgr@${PROJECT_ID}.iam.gserviceaccount.com"
REPO="https://github.com/sonmap/Gcp_Managed_GKE_L2Comm.git"
DIRECTORY="terraform/30-batch"
REF="main"

gcloud config set project "${PROJECT_ID}"

gcloud infra-manager deployments apply \
  "projects/${PROJECT_ID}/locations/${REGION}/deployments/${DEPLOYMENT_ID}" \
  --service-account="projects/${PROJECT_ID}/serviceAccounts/${INFRA_SA}" \
  --git-source-repo="${REPO}" \
  --git-source-directory="${DIRECTORY}" \
  --git-source-ref="${REF}"
