# Gcp_Managed_GKE_L2Comm

GKE Autopilot에서 Python 배치 Job을 실행하는 PoC입니다.

## Target architecture

- Shared VPC Host Project: `gcp-prod-edp-hub-vpchost`
- Existing VPC: `vpc-prod-edp-hub`
- Service/Workload Project: `gcp-prod-edp-edge-509423`
- BigQuery target: `pjt-c-admin.dlk_sample.gcp_region_inventory`
- Region: `asia-northeast3`
- GKE mode: Autopilot

### Network

- GKE node primary: `10.254.0.0/28`
- Pod secondary: `10.254.2.0/23`
- Service secondary: `10.254.4.0/24`
- Control plane: `10.254.5.0/28`

## Terraform stages

| Stage | Run method | Purpose |
|---|---|---|
| `00-bootstrap` | VM / `admin@sonmap.net` | APIs, delegated Terraform SA, Infra Manager SA, IAM |
| `10-network` | VM / `admin@sonmap.net` -> `sa-l2comm-tf-admin` impersonation | Attach Shared VPC service project, GKE subnet, Shared VPC IAM |
| `20-platform` | VM / `admin@sonmap.net` -> `sa-l2comm-tf-admin` impersonation | GKE Autopilot, Artifact Registry, runtime/build/workflow SAs |
| `21-app` | VM / `admin@sonmap.net` -> `sa-l2comm-tf-admin` impersonation | Namespace, KSA, Workload Identity binding |
| `30-batch` | Infrastructure Manager | Workflow + Cloud Scheduler |

## Authentication model

Execution VM attached service account:

`620081195575-compute@developer.gserviceaccount.com`

Bootstrap creates:

- `sa-l2comm-tf-admin@gcp-prod-edp-edge-509423.iam.gserviceaccount.com`
- `sa-l2comm-inframgr@gcp-prod-edp-edge-509423.iam.gserviceaccount.com`
- `sa-l2comm-runtime@gcp-prod-edp-edge-509423.iam.gserviceaccount.com`
- `sa-l2comm-workflow@gcp-prod-edp-edge-509423.iam.gserviceaccount.com`
- `sa-l2comm-cloudbuild@gcp-prod-edp-edge-509423.iam.gserviceaccount.com`

Stages 00/10/20/21 are initiated from `admin@sonmap.net`. Stages 10/20/21 immediately delegate Terraform permissions to `sa-l2comm-tf-admin`, so administrator credentials are not embedded in Terraform configuration/state. The VM service account is also allowed to impersonate this delegated SA for recovery/automation.

Stage 30 is executed by Infrastructure Manager using `sa-l2comm-inframgr`.

## Runtime flow

```text
Source change
  -> Cloud Build
  -> Artifact Registry

Scheduled execution
  -> Cloud Scheduler
  -> Workflow
  -> gke.create_job
  -> Kubernetes Job
  -> GKE Autopilot creates Pod
  -> Pod pulls Artifact Registry image
  -> python main.py
  -> Compute Regions API lists Google Cloud region metadata
  -> pjt-c-admin.dlk_sample.gcp_region_inventory
```

## Apply order

```bash
# 00 as admin@sonmap.net
bash scripts/apply-00-as-admin.sh

# 10/20/21 initiated as admin@sonmap.net and delegated to sa-l2comm-tf-admin
bash scripts/apply-10-21.sh

# Build Python container once/source change only
bash scripts/build-image.sh

# 30 through Infrastructure Manager
bash scripts/deploy-infra-manager-30.sh
```

## Important

- `pjt-c-admin.dlk_sample` must already exist.
- Stage 10 creates `subnet-prod-edp-l2comm-gke-an3` inside existing `vpc-prod-edp-hub`; it does not create a new VPC.
- The first image build must finish before Scheduler executes the workflow.
- The PoC grants broad bootstrap permissions to `sa-l2comm-tf-admin`; narrow them after validation.
