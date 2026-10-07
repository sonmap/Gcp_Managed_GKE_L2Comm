# 90-destroy

기존 `Gcp_Managed_GKE_L2Comm` 환경을 정리하기 위한 **삭제/초기화 단계**입니다.

현재 구성은 생성 방식이 두 가지로 나뉘어 있습니다.

| 단계 | 생성 방식 | 삭제 방식 |
|---|---|---|
| 40-scheduler | `gcloud scheduler jobs create` | gcloud로 삭제 |
| 30-infra-manager | Infrastructure Manager | **Infra Manager deployment delete** |
| 10-network | 직접 Terraform | Terraform destroy |
| 00-bootstrap | 직접 Terraform | 기본 보존 |

## 중요

`l2comm-platform` Infrastructure Manager Deployment를 삭제하면
해당 Deployment의 Terraform state에 포함된 리소스도 같이 삭제됩니다.

30 단계 기준 주요 삭제 대상:

- GKE Autopilot `gke-l2comm-batch-an3`
- Artifact Registry `ar-l2comm-python`
- Artifact Registry `ar-l2comm-helm`
- `sa-l2comm-runtime`
- `sa-l2comm-workflow`
- `sa-l2comm-cloudbuild`
- 관련 IAM Binding
- Workload Identity Binding
- Workflow `wf-l2comm-gke-job`
- Cloud Build Trigger `trg-l2comm-python-image`

다음은 **Infra Manager가 관리하지 않으므로 deployment delete만으로 삭제되지 않습니다.**

- Cloud Scheduler `sch-l2comm-gke-job`
- Shared VPC Subnet / Secondary Range
- Shared VPC Service Project 연결
- 00-bootstrap의 TF State Bucket / Terraform SA / Infra Manager SA
- BigQuery Dataset/Table 자체

---

## 1. 현재 Infra Manager 관리 리소스 확인

```bash
REVISION=$(gcloud infra-manager deployments describe l2comm-platform \
  --project=gcp-prod-edp-edge-509423 \
  --location=asia-northeast3 \
  --format='value(latestRevision)')

gcloud infra-manager resources list \
  --revision="$REVISION"
```

삭제 전에 반드시 이 목록을 확인합니다.

---

## 2. 권장: Platform 삭제

L2Comm02로 전환할 때는 **platform 모드**로 먼저 기존 Scheduler와
Infra Manager Deployment를 정리합니다.

```bash
cd ~/Gcp_Managed_GKE_L2Comm
git pull

bash 90-destroy/destroy-all.sh platform
```

처리 순서:

```text
Cloud Scheduler pause/delete
        ↓
Infra Manager 관리 리소스 목록 출력
        ↓
사용자 확인
        ↓
gcloud infra-manager deployments delete
        ↓
GKE / AR / SA / IAM / Workflow / Trigger 삭제
```

Google Cloud Infrastructure Manager에서 Deployment를 삭제하면
그 Deployment가 관리하는 기반 리소스도 같이 삭제됩니다.

---

## 3. Network까지 전체 삭제

기존 `10-network` Terraform state까지 제거하려면:

```bash
bash 90-destroy/destroy-all.sh full
```

`full` 모드는 Platform 삭제 후 다음을 추가 수행합니다.

```text
terraform/10-network
        ↓
terraform plan -destroy
        ↓
사용자 확인
        ↓
terraform apply destroy plan
```

삭제 대상에는 아래 기존 Network 구성이 포함될 수 있습니다.

```text
subnet-prod-edp-l2comm-gke-an3
  Primary          10.254.0.0/28
  Pod Secondary    10.254.2.0/23
  Service Secondary 10.254.4.0/24
```

> `full` 실행 전 반드시 10-network Terraform state가 현재 실제 Network를
> 관리하고 있는지 확인합니다. state가 없으면 스크립트가 Network 삭제를 중단합니다.

---

## 4. 00-bootstrap은 기본 보존

L2Comm02 재구축에 아래 자원을 다시 사용할 수 있으므로 자동 삭제하지 않습니다.

- `sa-l2comm-inframgr`
- `sa-l2comm-tf-admin`
- Terraform state bucket
- API 활성화 / 기반 IAM

L2Comm02 전환 목적이면 **00-bootstrap은 보존하는 것이 권장**됩니다.

전체 PoC를 완전히 폐기할 때만 마지막에 별도로 검토합니다.

---

## 5. Infra Manager 명령만 직접 실행하는 방법

Scheduler 정리 후 Infra Manager Deployment 전체를 바로 삭제하려면:

```bash
gcloud infra-manager deployments delete \
  projects/gcp-prod-edp-edge-509423/locations/asia-northeast3/deployments/l2comm-platform
```

이 명령은 되돌릴 수 없는 리소스 삭제를 수행하므로,
먼저 `gcloud infra-manager resources list`로 관리 대상 확인을 권장합니다.

---

## 6. 삭제 확인

```bash
gcloud container clusters list \
  --project=gcp-prod-edp-edge-509423 \
  --region=asia-northeast3
```

```bash
gcloud infra-manager deployments describe l2comm-platform \
  --project=gcp-prod-edp-edge-509423 \
  --location=asia-northeast3
```

Deployment가 삭제되면 두 번째 명령은 Not Found가 정상입니다.

Network까지 삭제한 경우:

```bash
gcloud compute networks subnets describe subnet-prod-edp-l2comm-gke-an3 \
  --project=gcp-prod-edp-hub-vpchost \
  --region=asia-northeast3
```

Subnet이 삭제되면 Not Found가 정상입니다.
