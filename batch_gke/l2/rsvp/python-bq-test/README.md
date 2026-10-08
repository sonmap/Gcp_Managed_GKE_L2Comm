# BigQuery smoke test under repository project path

이 디렉터리는 NAS/NFS 경로를 사용하지 않고 Git repository 내부 경로에서 BigQuery 연결을 점검하기 위한 테스트 소스입니다.

## 경로

```text
~/Gcp_Managed_GKE_L2Comm/batch_gke/l2/rsvp/python-bq-test
```

## 보안 원칙

- 고객/운영 전용 프로젝트명, 데이터셋명, 테이블명, Docker image URI, 내부 NFS IP/path를 저장하지 않습니다.
- 인증 키(JSON)는 저장하지 않습니다.
- ADC / Workload Identity를 사용합니다.
- 테스트 데이터는 `pjt-c-admin.l2comm_test.sample_input`만 사용합니다.

## 1. 브랜치 및 최신 소스

```bash
cd ~/Gcp_Managed_GKE_L2Comm
git fetch origin
git checkout feature/50-gke-autopilot-test
git pull origin feature/50-gke-autopilot-test
```

## 2. 테스트 데이터셋/테이블 생성

```bash
cd ~/Gcp_Managed_GKE_L2Comm/batch_gke/l2/rsvp/python-bq-test
chmod +x create_test_table.sh
./create_test_table.sh
```

기본 생성 대상:

```text
pjt-c-admin.l2comm_test.sample_input
```

## 3. Python BigQuery 연결 확인

```bash
set -a
source TEST_ENV.example
set +a

python3 -m pip install --user google-cloud-bigquery google-auth pyarrow
python3 bq_smoke_test.py
```

정상 시 `SELECT 1`, table metadata 조회, sample row 조회가 모두 `[OK]`로 출력됩니다.

Query job project는 `gcp-prod-edp-edge-509423`, source table은 `pjt-c-admin`으로 분리되어 있습니다.
