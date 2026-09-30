# Python BigQuery smoke test for GKE Autopilot

목적: 신규 Autopilot Pod에서 **인증과 타 프로젝트 BigQuery 접근 권한만** 안전하게 점검한다.

## 보안 원칙

- 운영/고객 프로젝트명은 소스에 저장하지 않는다.
- 서비스 계정 JSON key 경로를 소스에 저장하지 않는다.
- ADC / Workload Identity만 사용한다.
- 데이터셋/테이블명은 Git에 커밋하지 않고 실행 시 환경변수로만 전달한다.
- 기본값은 `BQ_READ_ONLY=1`이며 DROP/WRITE 검증은 수행하지 않는다.

## 프로젝트 기본값

```text
Query Job Project     : gcp-prod-edp-edge-509423
VPSH Source Project   : pjt-c-admin
RKDG Source Project   : pjt-c-admin
PARSE Source Project1 : pjt-c-admin
PARSE Source Project2 : gcp-prod-edp-hub-vpchost
```

## 1. 인증/Query Job만 확인

```bash
cd ~/Gcp_Managed_GKE_L2Comm/50-gke-autopilot-test/python-bq-test

set -a
source TEST_ENV.example
set +a

python3 -m pip install --user google-cloud-bigquery google-auth pyarrow
python3 bq_smoke_test.py
```

데이터셋/테이블을 지정하지 않으면 `SELECT 1`만 수행되고 개별 테이블 검사는 `[SKIP]` 된다.

## 2. 실제 테이블 읽기 확인

실제 식별자는 **쉘에서만 설정**하고 Git에는 커밋하지 않는다.

```bash
export BQ_VPSH_SOURCE_DATASET="<dataset>"
export BQ_VPSH_SOURCE_TABLE="<table>"

export BQ_RKDG_SOURCE_DATASET="<dataset>"
export BQ_RKDG_SOURCE_TABLE="<table>"

export BQ_PARSE_SOURCE_DATASET_1="<dataset>"
export BQ_PARSE_SOURCE_TABLE_1="<table>"

export BQ_PARSE_SOURCE_DATASET_2="<dataset>"
export BQ_PARSE_SOURCE_TABLE_2="<table>"

python3 bq_smoke_test.py
```

## 필요한 IAM 방향

- `gcp-prod-edp-edge-509423`: BigQuery Job User
- `pjt-c-admin`: 필요한 Dataset에 BigQuery Data Viewer
- `gcp-prod-edp-hub-vpchost`: 필요한 Dataset에 BigQuery Data Viewer

쓰기 테스트는 현재 단계에서 하지 않는다.
