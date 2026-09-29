# Gcp_Managed_GKE_L2Comm

GKE Autopilot에서 Python 배치 Job을 실행하는 현재 PoC 구성입니다.

## 1. 현재 테스트 구조

```text
admin@sonmap.net
   |
   +-- 00-bootstrap (직접 Terraform)
   |     +-- API 활성화
   |     +-- Terraform/Infrastructure Manager 실행 SA
   |     +-- IAM
   |
   +-- 10-network (직접 Terraform)
   |     +-- Shared VPC Service Project 연결
   |     +-- GKE Subnet / Secondary Range
   |     +-- Shared VPC IAM
   |
   +-- Infrastructure Manager deployment
         deployment location: asia-northeast3
         execution SA: sa-l2comm-inframgr
         source: terraform/30-infra-manager
              |
              +-- target region: asia-northeast3
              +-- GKE Autopilot: gke-l2comm-batch-an3
              +-- Artifact Registry: ar-l2comm-python
              +-- Artifact Registry: ar-l2comm-helm
              +-- Runtime / Workflow / Cloud Build SA
              +-- Workload Identity IAM
              +-- Workflow: wf-l2comm-gke-job

infra-son01
   |
   +-- Helm local chart
         |
         +-- namespace: l2comm-batch
         +-- KSA: ksa-l2comm-batch
              |
              +-- Workload Identity
                   -> sa-l2comm-runtime

Cloud Scheduler
   |
   +-- Workflows Executions API
         |
         +-- wf-l2comm-gke-job
               |
               +-- gke.create_job
                     |
                     +-- Kubernetes Job
                           |
                           +-- GKE Autopilot Pod
                                 |
                                 +-- Artifact Registry image pull
                                 +-- python main.py
                                 +-- BigQuery write
```

## 2. 프로젝트 / 네트워크

| 구분 | 값 |
|---|---|
| Shared VPC Host | `gcp-prod-edp-hub-vpchost` |
| Shared VPC | `vpc-prod-edp-hub` |
| Service / Workload Project | `gcp-prod-edp-edge-509423` |
| BigQuery Project | `pjt-c-admin` |
| BigQuery Dataset | `dlk_sample` |
| BigQuery Table | `gcp_region_inventory` |
| GKE Target Region | `asia-northeast3` |
| GKE Cluster | `gke-l2comm-batch-an3` |
| GKE Subnet | `subnet-prod-edp-l2comm-gke-an3` |

### GKE CIDR

| 용도 | CIDR |
|---|---|
| Node Primary | `10.254.0.0/28` |
| Pod Secondary | `10.254.2.0/23` |
| Service Secondary | `10.254.4.0/24` |
| Control Plane | `10.254.5.0/28` |

GKE는 Private Autopilot이며 별도 Cloud NAT를 사용하지 않는 테스트 구조입니다.
Container Image와 Helm OCI Repository는 Artifact Registry를 사용합니다.

## 3. 현재 적용 단계

| Stage | 실행 주체 | 역할 |
|---|---|---|
| `terraform/00-bootstrap` | `admin@sonmap.net` | API, tfstate bucket, Terraform SA, Infra Manager SA, IAM |
| `terraform/10-network` | `admin@sonmap.net` | Shared VPC 연결, GKE subnet, secondary range, network IAM |
| `terraform/30-infra-manager` | Infrastructure Manager / `sa-l2comm-inframgr` | GKE, AR, Runtime SA, Workflow SA, Cloud Build SA, Workload Identity IAM, Workflow |
| `40-scheduler` | `admin@sonmap.net` / gcloud | Cloud Scheduler 생성 및 Workflow 정기 호출 |

이전 테스트용 `20-platform`, `21-app`, `30-batch`는 제거했습니다.
`scripts/*.sh`도 제거하고 실제 명령을 직접 실행하는 방식으로 정리했습니다.

## 4. Service Account / Identity

| 계정 | 역할 |
|---|---|
| `admin@sonmap.net` | 00-bootstrap, 10-network 직접 실행 및 관리 |
| `620081195575-compute@developer.gserviceaccount.com` | `infra-son01` VM 기본 SA |
| `sa-l2comm-tf-admin@gcp-prod-edp-edge-509423.iam.gserviceaccount.com` | Bootstrap에서 생성되는 Terraform 관리용 SA |
| `sa-l2comm-inframgr@gcp-prod-edp-edge-509423.iam.gserviceaccount.com` | Infrastructure Manager Terraform 실행 SA |
| `sa-l2comm-runtime@gcp-prod-edp-edge-509423.iam.gserviceaccount.com` | GKE 업무 Pod가 Workload Identity로 사용하는 GSA |
| `sa-l2comm-workflow@gcp-prod-edp-edge-509423.iam.gserviceaccount.com` | Workflow 실행 SA 및 Scheduler OAuth 호출 SA |
| `sa-l2comm-cloudbuild@gcp-prod-edp-edge-509423.iam.gserviceaccount.com` | Python Container Image Build용 SA |
| `ksa-l2comm-batch` | GKE Namespace 내부 KSA. `sa-l2comm-runtime`과 Workload Identity 연결 |

### Identity 흐름

```text
Cloud Scheduler
  -> OAuth: sa-l2comm-workflow
  -> Workflow 실행

Workflow
  -> sa-l2comm-workflow
  -> GKE Kubernetes Job 생성

Pod
  -> KSA: ksa-l2comm-batch
  -> Workload Identity
  -> GSA: sa-l2comm-runtime
  -> BigQuery / Compute API

Cloud Build
  -> sa-l2comm-cloudbuild
  -> Artifact Registry push

Infrastructure Manager
  -> sa-l2comm-inframgr
  -> GKE / AR / IAM / Workflow 생성
```

## 5. Build / Runtime 흐름

### Image Build

```text
app/main.py
   -> Cloud Build
   -> Docker Image
   -> Artifact Registry: ar-l2comm-python
```

Cloud Build 설정:

```text
cloudbuild/cloudbuild.yaml
```

### Runtime

```text
Cloud Scheduler
   -> Workflow 실행
   -> gke.create_job
   -> Kubernetes Job
   -> Autopilot Pod
   -> AR Image Pull
   -> python main.py
   -> Google Compute Regions API 조회
   -> pjt-c-admin.dlk_sample.gcp_region_inventory 저장
```

현재 테스트 Job Pod 자원값은 `terraform/30-infra-manager/workflow.yaml.tftpl`에 있습니다.

```yaml
resources:
  requests:
    cpu: "250m"
    memory: "512Mi"
  limits:
    cpu: "250m"
    memory: "512Mi"
```

이 값은 GKE Autopilot Node 크기를 고정하는 값이 아니라 업무 Pod의 요청/제한 값입니다.
업무별 Pod 크기가 달라질 경우 Workflow 실행 인자로 CPU/Memory를 넘기는 방식으로 확장할 수 있습니다.

## 6. Helm / NAT 없는 구조

Helm은 Public Helm Repository에서 직접 다운로드하지 않습니다.

```text
helm/l2comm-batch
   -> KSA 생성
   -> sa-l2comm-runtime annotation
```

현재 Helm Chart는 Namespace 생성 후 KSA bootstrap 용도입니다.
Container Image는 아래 Artifact Registry를 사용합니다.

```text
asia-northeast3-docker.pkg.dev/gcp-prod-edp-edge-509423/ar-l2comm-python/python-bq-batch:v1
```

Helm OCI 저장소:

```text
oci://asia-northeast3-docker.pkg.dev/gcp-prod-edp-edge-509423/ar-l2comm-helm
```

## 7. 적용 순서

### 1) Bootstrap

```bash
cd terraform/00-bootstrap
terraform init
terraform plan
terraform apply
```

### 2) Shared VPC / Network

```bash
cd ../10-network
terraform init
terraform plan
terraform apply
```

### 3) Infrastructure Manager

Infrastructure Manager deployment와 생성 대상 GKE/AR/Workflow 모두 `asia-northeast3`를 사용합니다.

```bash
gcloud infra-manager deployments apply \
  projects/gcp-prod-edp-edge-509423/locations/asia-northeast3/deployments/l2comm-platform \
  --service-account=projects/gcp-prod-edp-edge-509423/serviceAccounts/sa-l2comm-inframgr@gcp-prod-edp-edge-509423.iam.gserviceaccount.com \
  --git-source-repo=https://github.com/sonmap/Gcp_Managed_GKE_L2Comm.git \
  --git-source-directory=terraform/30-infra-manager \
  --git-source-ref=main
```

### 4) Helm bootstrap

GKE가 `RUNNING` 된 뒤 `infra-son01`에서 local Helm Chart를 사용하여 Namespace/KSA를 적용합니다.

### 5) 40-scheduler

Cloud Scheduler는 Terraform이 아니라 gcloud 명령어로 구성합니다.
상세 명령은 `40-scheduler/README.md`를 사용합니다.

```text
Cloud Scheduler
  -> wf-l2comm-gke-job
  -> GKE Job
  -> Autopilot Pod
```

## 8. 현재 Repository 구조

```text
Gcp_Managed_GKE_L2Comm/
├─ README.md
├─ app/
│  ├─ Dockerfile
│  ├─ main.py
│  └─ requirements.txt
├─ cloudbuild/
│  └─ cloudbuild.yaml
├─ helm/
│  └─ l2comm-batch/
│     ├─ Chart.yaml
│     ├─ values.yaml
│     └─ templates/
│        └─ serviceaccount.yaml
├─ 40-scheduler/
│  └─ README.md
└─ terraform/
   ├─ 00-bootstrap/
   ├─ 10-network/
   └─ 30-infra-manager/
      ├─ main.tf
      ├─ variables.tf
      ├─ terraform.tfvars.example
      └─ workflow.yaml.tftpl
```
