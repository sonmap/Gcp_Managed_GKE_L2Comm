# Python BigQuery smoke test for GKE Autopilot

목적: 기존 Python 소스가 참조하는 BigQuery 프로젝트/데이터셋을 운영 변경 없이 읽기 전용으로 점검한다.

## AS-IS에서 확인된 BigQuery 위치

- Query job / 기본 project: `gcp-prod-edp-lake`
- VPSH source: `gcp-prod-edp-lake.DLKL2RSVP.L2VP_VPSH_ANAL_MART_H`
- RKDG source: `gcp-prod-edp-lake.DLKT2RSVP.L2VP_RKDG_CALL_SMS_TRAIN_MART_TMP`
- PARSE source 1: `gcp-prod-edp-lake.DLKVW.LOHW_TB_VPSH_DCL_INFO`
- PARSE source 2: `gcp-sbx-edp-rsvp.DLKVWE.LOHW_TB_VPSH_DCL_INFO_CZ`

기존 `config.py`의 `/home/jupyter/.oef` JSON key 의존성은 신규 Autopilot에서 사용하지 않는 것을 기본으로 한다. `BQ_AUTH_PATH`가 비어 있으면 ADC / Workload Identity를 사용한다.

## 테스트

```bash
cd ~/Gcp_Managed_GKE_L2Comm/50-gke-autopilot-test/python-bq-test

set -a
source TEST_ENV.example
set +a

python3 -m pip install --user google-cloud-bigquery google-auth pyarrow
python3 bq_smoke_test.py
```

`BQ_READ_ONLY=1`이 기본이므로 DROP/WRITE 테스트는 하지 않는다.

예상 출력:

```text
JOB_PROJECT=gcp-prod-edp-edge-509423
AUTH=ADC/Workload Identity
[OK] query job / SELECT 1 => 1
[OK] VPSH: ...
[OK] RKDG: ...
[OK] PARSE-1: ...
[OK] PARSE-2: ...
```

`SELECT 1` 실패 시 신규 Autopilot Pod의 Google IAM / Workload Identity부터 확인한다. 특정 table만 FAIL이면 해당 source dataset에 Data Viewer 권한을 확인한다.

## 필요한 권한 방향

- `gcp-prod-edp-edge-509423`: BigQuery Job User
- source datasets/projects: BigQuery Data Viewer
- 쓰기 테스트를 나중에 할 경우 `DLKT2RSVP_TEST` 데이터셋에만 Data Editor 권한 부여

운영 `DLKT2RSVP`에 직접 쓰기 테스트하지 않는다.
