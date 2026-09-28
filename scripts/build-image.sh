#!/usr/bin/env bash
set -euo pipefail

PROJECT_ID="gcp-prod-edp-edge-509423"
REGION="asia-northeast3"
REPOSITORY="ar-l2comm-python"
IMAGE_NAME="python-bq-batch"
IMAGE_TAG="v1"
TF_ADMIN_SA="sa-l2comm-tf-admin@${PROJECT_ID}.iam.gserviceaccount.com"
BUILD_SA="sa-l2comm-cloudbuild@${PROJECT_ID}.iam.gserviceaccount.com"
IMAGE_URI="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPOSITORY}/${IMAGE_NAME}:${IMAGE_TAG}"

gcloud config set project "${PROJECT_ID}"

gcloud builds submit . \
  --config=cloudbuild/cloudbuild.yaml \
  --substitutions=_IMAGE_URI="${IMAGE_URI}" \
  --service-account="projects/${PROJECT_ID}/serviceAccounts/${BUILD_SA}" \
  --impersonate-service-account="${TF_ADMIN_SA}"

echo "Built: ${IMAGE_URI}"
