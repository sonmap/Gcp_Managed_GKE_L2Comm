# 50 - GKE Standard -> Autopilot Target Test

목적: `gcp-prod-edp-hub-vpchost` 프로젝트의 실행 VM에서 기존 wrapper 호출 구조를 유지하고, Kubernetes target만 `gcp-prod-edp-edge-509423`의 `gke-l2comm-batch-an3`로 전환하여 1차 이관 가능 여부를 검증한다.

## 보안 원칙

- 고객/운영 전용 Docker image URI는 Git에 저장하지 않는다.
- 과거 운영 프로젝트명, 내부 저장소 IP, NFS 경로는 Git에 저장하지 않는다.
- BigQuery 실제 데이터셋/테이블명은 Git에 저장하지 않고 실행 환경변수로만 전달한다.
- Service Account JSON key를 Git에 저장하지 않는다. ADC / Workload Identity를 사용한다.

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

## 구성

- `setup-kubeconfig.sh`: 대상 Autopilot 전용 kubeconfig 생성
- `bootstrap-namespace.sh`: 테스트 namespace/ServiceAccount 생성
- `precheck.sh`: Kubernetes 권한 사전 점검
- `run-gke.sh`: generic wrapper
- `client_gke`: GKE Pod 실행. `USE_NFS=0` 기본
- `python-bq-test/`: ADC 기반 BigQuery read-only smoke test

## 1. kubeconfig 생성

```bash
cd ~/Gcp_Managed_GKE_L2Comm/50-gke-autopilot-test
chmod +x setup-kubeconfig.sh bootstrap-namespace.sh precheck.sh run-gke.sh client_gke

./setup-kubeconfig.sh
./bootstrap-namespace.sh
./precheck.sh
```

## 2. NFS 없이 Pod 테스트

Docker image URI는 Git에 넣지 않고 실행할 때만 지정한다.

```bash
export CLIENT_COMMON="$PWD/client_common.test"
export CLIENT_GKE="$PWD/client_gke"
export DOCKER_IMAGE="<TEST_IMAGE_URI>"
export USE_NFS=0
export KEEP_RESOURCES=1

./run-gke.sh \
  20260930 20260930 20260930 130000 \
  0 1 2 \
  /tmp /bin/echo AUTOPILOT_OK
```

테스트 후:

```bash
kubectl get pod -n nms-prd
kubectl get events -n nms-prd --sort-by=.lastTimestamp | tail -20
```

`KEEP_RESOURCES=0`이 기본값이며 정상 종료/중단 시 테스트 자원을 정리한다.

## 3. BigQuery 연결 테스트

```bash
cd python-bq-test
set -a
source TEST_ENV.example
set +a
python3 bq_smoke_test.py
```

기본 테스트는 `SELECT 1`만 수행한다. 실제 데이터셋/테이블 검증이 필요할 때만 shell 환경변수로 식별자를 넣고 재실행한다.

## NFS가 필요한 경우

현재 테스트의 기본값은 `USE_NFS=0`이다. 추후 별도 storage 검증 시에만 다음 값을 shell에서 전달한다.

```bash
export USE_NFS=1
export NFS_SERVER="<NFS_IP>"
export NFS_BASE_PATH="<EXPORT_PATH>"
export NFS_MOUNT_PATH="/mnt/shared"
```

NFS 서버 IP와 export path는 Git에 커밋하지 않는다.
