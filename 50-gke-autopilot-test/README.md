# 50 - GKE Standard -> Autopilot Target Test

목적: 기존 Edge 서버의 `run-gke.sh -> /ssw/dlk/client_gke` 호출 구조를 유지하고, **KUBECONFIG 대상만 신규 프로젝트의 GKE Autopilot로 변경**하여 1차 이관 가능 여부를 확인한다.

## 구성

- `setup-kubeconfig.sh` : 신규 프로젝트 Autopilot용 별도 kubeconfig 생성
- `precheck.sh` : context / namespace / Pod/PV/PVC 권한 확인
- `run-gke.sh` : 기존 `run-gke.sh` 호출 형태를 유지한 테스트용 사본
- `client_gke` : 기존 `client_gke` 흐름(PV -> PVC -> Pod -> log -> cleanup)을 유지하고 target을 환경변수로 선택 가능하게 한 테스트용 사본
- `client_common.test` : 운영 `/ssw/dlk/client_common`이 없는 환경에서도 wrapper 흐름을 확인하기 위한 최소 stub

> 운영 파일을 직접 덮어쓰지 않는다. 먼저 이 폴더에서 신규 Autopilot target을 검증한 후 운영 `client_gke`의 KUBECONFIG 한 줄을 전환하는 방식으로 사용한다.

## 1. 신규 Autopilot kubeconfig 생성

```bash
cd 50-gke-autopilot-test
chmod +x setup-kubeconfig.sh precheck.sh run-gke.sh client_gke

export TARGET_PROJECT_ID="<NEW_PROJECT_ID>"
export TARGET_CLUSTER="<NEW_AUTOPILOT_CLUSTER>"
export TARGET_REGION="asia-northeast3"
export TARGET_KUBECONFIG="$HOME/.kube/config_new-autopilot"

./setup-kubeconfig.sh
```

Private control plane에서 내부 Endpoint를 반드시 사용해야 하는 환경이면 `setup-kubeconfig.sh`의 `get-credentials` 명령에 `--internal-ip`를 추가한다.

확인 포인트:

```bash
KUBECONFIG="$HOME/.kube/config_new-autopilot" kubectl config current-context
KUBECONFIG="$HOME/.kube/config_new-autopilot" kubectl get ns
```

## 2. 권한 사전 점검

기존 소스는 `nms-prd` namespace와 `nms-prd-sa` ServiceAccount를 사용한다.

```bash
export TARGET_KUBECONFIG="$HOME/.kube/config_new-autopilot"
export TARGET_NAMESPACE="nms-prd"
./precheck.sh
```

신규 클러스터에 테스트용 namespace/SA가 아직 없다면 별도 테스트 환경에서만 생성:

```bash
KUBECONFIG="$TARGET_KUBECONFIG" kubectl create namespace nms-prd
KUBECONFIG="$TARGET_KUBECONFIG" kubectl create serviceaccount nms-prd-sa -n nms-prd
```

## 3. Manifest만 확인 (자원 생성 안 함)

```bash
export CLIENT_COMMON="$PWD/client_common.test"
export CLIENT_GKE="$PWD/client_gke"
export TARGET_KUBECONFIG="$HOME/.kube/config_new-autopilot"
export DRY_RUN=1

bash ./run-gke.sh \
  20260930 20260930 20260930 130000 \
  0 1 2 \
  /tmp /bin/echo AUTOPILOT_DRY_RUN
```

이 단계는 PV/PVC/Pod YAML까지만 출력하고 신규 GKE에는 아무 자원도 생성하지 않는다.

## 4. 신규 Autopilot 실제 Pod 테스트

```bash
unset DRY_RUN
export CLIENT_COMMON="$PWD/client_common.test"
export CLIENT_GKE="$PWD/client_gke"
export TARGET_KUBECONFIG="$HOME/.kube/config_new-autopilot"
export TARGET_NAMESPACE="nms-prd"
export POD_STATUS_CHK_INTERVAL_SEC=5
export POD_PENDING_CHK_UTMOST_CNT=120

bash ./run-gke.sh \
  20260930 20260930 20260930 130000 \
  0 1 2 \
  /tmp /bin/echo AUTOPILOT_OK
```

기본 Docker image는 기존 AS-IS와 동일하다.

```text
asia-northeast3-docker.pkg.dev/gcp-prod-edp-edge/dlk/lgplus-deeplearning:2.3-rsvp-rsvp-001-1
```

따라서 신규 프로젝트 Autopilot의 node service account가 기존 Edge 프로젝트 Artifact Registry image를 pull할 수 있어야 한다. 또한 Pod가 기존 NFS `10.136.209.130` 및 `/batch_gke/l2/...` 경로에 접근 가능해야 실제 테스트가 성공한다.

## 최종 운영 전환

테스트가 성공한 뒤 운영 `/ssw/dlk/client_gke`에서는 target만 다음과 같이 변경하면 된다.

```diff
- export KUBECONFIG=/home/$USER/.kube/config_prod-edge-cluster-3
+ export KUBECONFIG=/home/$USER/.kube/config_new-autopilot
```

`run-gke.sh` 업무 호출부는 그대로 유지한다.

## 이관 판단

1. `setup-kubeconfig.sh` 성공 -> Edge 실행 서버에서 신규 프로젝트 GKE API 접근 가능
2. `precheck.sh` 성공 -> Kubernetes Pod/PV/PVC 권한 준비 완료
3. `DRY_RUN=1` 성공 -> 기존 parameter -> manifest 변환 정상
4. 실제 Pod 성공 -> Artifact Registry + NFS + Autopilot 실행 호환성 확인
5. 이후 운영 `client_gke` KUBECONFIG target만 변경하여 단계적 전환
