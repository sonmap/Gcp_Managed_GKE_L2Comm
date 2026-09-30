# 50 - GKE Standard -> Autopilot Target Test

목적: `gcp-prod-edp-hub-vpchost` 프로젝트의 실행 VM에서 기존 `run-gke.sh -> client_gke` 구조를 유지하고, Kubernetes target만 신규 GKE Autopilot로 전환하여 1차 이관 가능 여부를 검증한다.

## 대상

| 구분 | 값 |
|---|---|
| 실행 VM 프로젝트 | `gcp-prod-edp-hub-vpchost` |
| 대상 GKE 프로젝트 | `gcp-prod-edp-edge-509423` |
| 대상 Cluster | `gke-l2comm-batch-an3` |
| Region | `asia-northeast3` |
| 테스트 Namespace | `nms-prd` |
| Kubernetes ServiceAccount | `nms-prd-sa` |
| kubeconfig | `$HOME/.kube/config_gke-l2comm-batch-an3` |

> VM 프로젝트와 GKE 프로젝트가 달라도 문제 없다. kubeconfig에 대상 프로젝트의 GKE API endpoint/context가 저장되며, VM에서 사용하는 Google 계정 또는 Service Account가 대상 프로젝트 GKE 접근 권한을 가져야 한다.

## 구성

- `setup-kubeconfig.sh` : 대상 Autopilot 전용 kubeconfig 생성
- `bootstrap-namespace.sh` : 신규 cluster에 `nms-prd`와 `nms-prd-sa` 생성
- `precheck.sh` : context / namespace / Pod/PV/PVC 권한 확인
- `run-gke.sh` : 기존 `run-gke.sh` 호출 형태를 유지한 테스트용 사본
- `client_gke` : 기존 `client_gke` 흐름(PV -> PVC -> Pod -> log -> cleanup)을 유지한 테스트용 사본
- `client_common.test` : 운영 `/ssw/dlk/client_common` 없이 wrapper 흐름을 확인하기 위한 stub

운영 파일은 직접 덮어쓰지 않는다. 이 폴더에서 신규 Autopilot target 검증 후 운영 `client_gke`의 KUBECONFIG target만 전환한다.

## 1. kubeconfig 생성

기본 target 값은 소스에 이미 반영되어 있다.

```bash
cd 50-gke-autopilot-test
chmod +x setup-kubeconfig.sh bootstrap-namespace.sh precheck.sh run-gke.sh client_gke

./setup-kubeconfig.sh
```

실행되는 핵심 명령은 다음과 같다.

```bash
gcloud container clusters get-credentials gke-l2comm-batch-an3 \
  --region asia-northeast3 \
  --project gcp-prod-edp-edge-509423
```

Private control plane의 내부 endpoint를 사용해야 하는 경우:

```bash
USE_INTERNAL_IP=1 ./setup-kubeconfig.sh
```

확인:

```bash
KUBECONFIG="$HOME/.kube/config_gke-l2comm-batch-an3" kubectl config current-context
KUBECONFIG="$HOME/.kube/config_gke-l2comm-batch-an3" kubectl get ns
```

## 2. Namespace / ServiceAccount 준비

Namespace는 프로젝트 자원이 아니라 **각 GKE cluster 내부 자원**이다. 따라서 신규 `gke-l2comm-batch-an3`에 `nms-prd`가 없다면 별도로 만들어야 한다. 기존 `client_gke`가 `nms-prd-sa`를 지정하므로 ServiceAccount도 신규 cluster에 필요하다.

```bash
./bootstrap-namespace.sh
```

이 스크립트는 이미 존재하면 재사용하고, 없을 때만 다음을 생성한다.

```text
namespace/nms-prd
serviceaccount/nms-prd-sa
```

> `nms-prd-sa`가 Workload Identity로 GCP API를 호출해야 하는 업무라면 KSA 생성만으로 끝나지 않는다. GSA 연결/IAM 설정은 별도 적용한다.

## 3. 권한 사전 점검

```bash
./precheck.sh
```

Pod/PVC는 `nms-prd` namespace 권한을 확인하고, PV는 cluster-scoped 권한을 확인한다.

## 4. Manifest만 확인 - Kubernetes 자원 생성 안 함

```bash
export CLIENT_COMMON="$PWD/client_common.test"
export CLIENT_GKE="$PWD/client_gke"
export DRY_RUN=1

bash ./run-gke.sh \
  20260930 20260930 20260930 130000 \
  0 1 2 \
  /tmp /bin/echo AUTOPILOT_DRY_RUN
```

## 5. 신규 Autopilot 실제 Pod 테스트

```bash
unset DRY_RUN
export CLIENT_COMMON="$PWD/client_common.test"
export CLIENT_GKE="$PWD/client_gke"
export POD_STATUS_CHK_INTERVAL_SEC=5
export POD_PENDING_CHK_UTMOST_CNT=120

bash ./run-gke.sh \
  20260930 20260930 20260930 130000 \
  0 1 2 \
  /tmp /bin/echo AUTOPILOT_OK
```

기본 Docker image와 NFS 설정은 AS-IS를 유지한다.

```text
Docker image:
asia-northeast3-docker.pkg.dev/gcp-prod-edp-edge/dlk/lgplus-deeplearning:2.3-rsvp-rsvp-001-1

NFS:
10.136.209.130
/batch_gke/l2/...
```

따라서 실제 테스트에서는 신규 Autopilot의 image pull 권한과 `10.136.209.130` NFS 네트워크 접근을 함께 확인해야 한다.

## 운영 전환 시 변경점

AS-IS:

```bash
export KUBECONFIG=/home/$USER/.kube/config_prod-edge-cluster-3
```

TO-BE:

```bash
export KUBECONFIG=/home/$USER/.kube/config_gke-l2comm-batch-an3
```

`run-gke.sh` 업무 호출부는 그대로 유지한다.
