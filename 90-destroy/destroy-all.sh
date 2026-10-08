#!/usr/bin/env bash
set -euo pipefail

PROJECT_ID="gcp-prod-edp-edge-509423"
LOCATION="asia-northeast3"
DEPLOYMENT_ID="l2comm-platform"
SCHEDULER_JOB="sch-l2comm-gke-job"
WORKFLOW_NAME="wf-l2comm-gke-job"

MODE="${1:-platform}"

if [[ "$MODE" != "platform" && "$MODE" != "full" ]]; then
  echo "Usage: bash 90-destroy/destroy-all.sh [platform|full]"
  echo "  platform : Scheduler + Infra Manager deployment 삭제"
  echo "  full     : platform 삭제 + terraform/10-network destroy"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DEPLOYMENT_FULL_NAME="projects/${PROJECT_ID}/locations/${LOCATION}/deployments/${DEPLOYMENT_ID}"

echo
echo "============================================================"
echo " L2Comm destroy"
echo "============================================================"
echo "Project    : ${PROJECT_ID}"
echo "Location   : ${LOCATION}"
echo "Deployment : ${DEPLOYMENT_ID}"
echo "Mode       : ${MODE}"
echo "============================================================"
echo

echo "[1/5] Scheduler 확인"
if gcloud scheduler jobs describe "$SCHEDULER_JOB"     --project="$PROJECT_ID"     --location="$LOCATION" >/dev/null 2>&1; then
  echo "Scheduler 발견: $SCHEDULER_JOB"
  gcloud scheduler jobs pause "$SCHEDULER_JOB"     --project="$PROJECT_ID"     --location="$LOCATION" || true
else
  echo "Scheduler 없음 - skip"
fi

echo
echo "[2/5] Infra Manager Deployment / 관리 리소스 확인"
if ! gcloud infra-manager deployments describe "$DEPLOYMENT_ID"     --project="$PROJECT_ID"     --location="$LOCATION" >/dev/null 2>&1; then
  echo "Infra Manager Deployment가 없습니다: $DEPLOYMENT_ID"
  DEPLOYMENT_EXISTS="no"
else
  DEPLOYMENT_EXISTS="yes"
  REVISION="$(gcloud infra-manager deployments describe "$DEPLOYMENT_ID"     --project="$PROJECT_ID"     --location="$LOCATION"     --format='value(latestRevision)')"

  echo "Latest revision: $REVISION"
  echo
  gcloud infra-manager resources list     --revision="$REVISION" || true
fi

echo
echo "삭제 범위:"
echo "  - Cloud Scheduler: $SCHEDULER_JOB"
echo "  - Infra Manager Deployment: $DEPLOYMENT_ID"
echo "    (GKE, AR, SA, IAM, Workflow, Cloud Build Trigger 등 state 관리 리소스)"
if [[ "$MODE" == "full" ]]; then
  echo "  - terraform/10-network state 관리 Network 자원"
fi
echo
echo "00-bootstrap은 삭제하지 않습니다."

if [[ "${CONFIRM_DESTROY:-}" != "YES" ]]; then
  read -r -p "계속하려면 DELETE-${DEPLOYMENT_ID} 를 입력하세요: " CONFIRM
  if [[ "$CONFIRM" != "DELETE-${DEPLOYMENT_ID}" ]]; then
    echo "취소되었습니다."
    exit 1
  fi
fi

echo
echo "[3/5] Scheduler 삭제"
if gcloud scheduler jobs describe "$SCHEDULER_JOB"     --project="$PROJECT_ID"     --location="$LOCATION" >/dev/null 2>&1; then
  gcloud scheduler jobs delete "$SCHEDULER_JOB"     --project="$PROJECT_ID"     --location="$LOCATION"     --quiet
else
  echo "Scheduler 없음 - skip"
fi

echo
echo "[4/5] Infra Manager Deployment 삭제"

# google_workflows_workflow has Terraform deletion_protection=true by default
# when the field was omitted in the historical state. Delete the Workflow
# directly first so a partially completed Infra Manager destroy can continue.
if gcloud workflows describe "$WORKFLOW_NAME"     --project="$PROJECT_ID"     --location="$LOCATION" >/dev/null 2>&1; then
  echo "Workflow 선삭제: $WORKFLOW_NAME"
  gcloud workflows delete "$WORKFLOW_NAME"     --project="$PROJECT_ID"     --location="$LOCATION"     --quiet
else
  echo "Workflow 없음 - skip"
fi

if [[ "$DEPLOYMENT_EXISTS" == "yes" ]]; then
  set +e
  DELETE_OUTPUT="$(gcloud infra-manager deployments delete "$DEPLOYMENT_FULL_NAME" --quiet 2>&1)"
  DELETE_RC=$?
  set -e

  echo "$DELETE_OUTPUT"

  if [[ $DELETE_RC -ne 0 ]]; then
    if echo "$DELETE_OUTPUT" | grep -q "cannot destroy workflow without setting deletion_protection=false"; then
      echo
      echo "Workflow Terraform deletion_protection으로 삭제가 중단되었습니다."
      echo "현재 destroy는 이미 일부 자원을 삭제했으므로 기존 Deployment를 재-apply하지 않습니다."
      echo "Workflow만 API로 직접 삭제한 뒤 Infra Manager delete를 재시도합니다."

      if gcloud workflows describe "$WORKFLOW_NAME"           --project="$PROJECT_ID"           --location="$LOCATION" >/dev/null 2>&1; then
        gcloud workflows delete "$WORKFLOW_NAME"           --project="$PROJECT_ID"           --location="$LOCATION"           --quiet
      else
        echo "Workflow가 이미 없습니다 - skip"
      fi

      echo
      echo "Infra Manager Deployment 삭제 재시도..."
      gcloud infra-manager deployments delete "$DEPLOYMENT_FULL_NAME" --quiet
    else
      echo
      echo "ERROR: Infra Manager Deployment 삭제 실패"
      echo "위 Cloud Build/Terraform 오류를 확인하세요."
      exit "$DELETE_RC"
    fi
  fi
else
  echo "Deployment 없음 - skip"
fi

echo
echo "Infra Manager 삭제 후 GKE 확인"
gcloud container clusters list   --project="$PROJECT_ID"   --region="$LOCATION" || true

if [[ "$MODE" == "full" ]]; then
  echo
  echo "[5/5] 10-network Terraform destroy"

  NETWORK_DIR="$REPO_ROOT/terraform/10-network"
  cd "$NETWORK_DIR"

  terraform init

  STATE_LIST="$(terraform state list 2>/dev/null || true)"
  if [[ -z "$STATE_LIST" ]]; then
    echo "ERROR: terraform/10-network state가 비어 있습니다."
    echo "Network를 자동 삭제하지 않습니다."
    echo "현재 Terraform state 위치/소유권을 확인한 후 수동으로 진행하세요."
    exit 2
  fi

  echo "현재 10-network state:"
  echo "$STATE_LIST"
  echo

  PLAN_FILE="/tmp/l2comm-10-network-destroy.tfplan"
  terraform plan -destroy -out="$PLAN_FILE"

  if [[ "${CONFIRM_NETWORK_DESTROY:-}" != "YES" ]]; then
    read -r -p "Network destroy를 계속하려면 DELETE-NETWORK 를 입력하세요: " CONFIRM_NET
    if [[ "$CONFIRM_NET" != "DELETE-NETWORK" ]]; then
      echo "Network 삭제는 취소되었습니다."
      exit 1
    fi
  fi

  terraform apply "$PLAN_FILE"
else
  echo
  echo "[5/5] Network 삭제 skip (platform mode)"
fi

echo
echo "============================================================"
echo " Destroy 단계 완료"
echo "============================================================"
echo
echo "확인:"
echo "gcloud container clusters list --project=$PROJECT_ID --region=$LOCATION"
echo "gcloud infra-manager deployments describe $DEPLOYMENT_ID --project=$PROJECT_ID --location=$LOCATION"
if [[ "$MODE" == "full" ]]; then
  echo "gcloud compute networks subnets describe subnet-prod-edp-l2comm-gke-an3 --project=gcp-prod-edp-hub-vpchost --region=$LOCATION"
fi
