# Gcp_Managed_GKE_L2Comm

GKE Autopilot에서 Python 배치 Job을 실행하는 PoC입니다.

## Target architecture

- Shared VPC Host Project: `gcp-prod-edp-hub-vpchost`
- Existing VPC: `vpc-prod-edp-hub`
- Service/Workload Project: `gcp-prod-edp-edge-509423`
- BigQuery target: `pjt-c-admin.dlk_sample`
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
| `00-bootstrap` | VM, bootstrap as `admin@sonmap.net` | APIs, delegated Terraform SA, Infra Manager SA, IAM |
| `10-network` | VM, delegated SA impersonation | Shared VPC subnet + GKE Shared VPC IAM |
| `20-platform` | VM, delegated SA impersonation | GKE Autopilot, Artifact Registry, runtime/build/workflow SAs |
| `21-app` | VM, delegated SA impersonation | Namespace/KSA and initial Cloud Build image build |
| `30-batch` | Infrastructure Manager | Workflow + Cloud Scheduler |

## Authentication model

The execution VM uses:

`620081195575-compute@developer.gserviceaccount.com`

`00-bootstrap` is the only bootstrap stage intended to be run with `admin@sonmap.net`. It creates `sa-l2comm-tf-admin` and grants both the VM service account and `admin@sonmap.net` permission to impersonate it. Stages 10/20/21 then use service-account impersonation instead of carrying admin credentials on the VM.

Infrastructure Manager executes stage 30 using `sa-l2comm-inframgr`.

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
  -> Autopilot creates Pod
  -> Pod pulls Artifact Registry image
  -> python main.py
  -> public BigQuery sample query
  -> pjt-c-admin.dlk_sample.gcp_public_sample
```

## Apply order

```bash
cd terraform/00-bootstrap && terraform init && terraform apply
cd ../10-network && terraform init && terraform apply
cd ../20-platform && terraform init && terraform apply
cd ../21-app && terraform init && terraform apply

# Build the first image
cd ../../
bash scripts/build-image.sh

# Stage 30 is deployed by Infrastructure Manager.
bash scripts/deploy-infra-manager-30.sh
```

> Review IAM and CIDRs before production use. The IAM roles in this PoC are intentionally operationally simple and should be narrowed after validation.
