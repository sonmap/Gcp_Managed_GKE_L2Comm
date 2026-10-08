#!/bin/bash
set -euo pipefail

PROJECT_ID="${BQ_SOURCE_PROJECT:-pjt-c-admin}"
DATASET_ID="${BQ_SOURCE_DATASET:-l2comm_test}"
TABLE_ID="${BQ_SOURCE_TABLE:-sample_input}"
LOCATION="${BQ_LOCATION:-asia-northeast3}"

if ! bq --project_id="$PROJECT_ID" show --dataset "$PROJECT_ID:$DATASET_ID" >/dev/null 2>&1; then
  bq --location="$LOCATION" --project_id="$PROJECT_ID" mk --dataset "$PROJECT_ID:$DATASET_ID"
fi

bq --project_id="$PROJECT_ID" query --use_legacy_sql=false <<SQL
CREATE OR REPLACE TABLE \`${PROJECT_ID}.${DATASET_ID}.${TABLE_ID}\` AS
SELECT 1 AS id, DATE '2026-09-30' AS p_yyyymmdd, 0.10 AS feature_01, 10 AS feature_02, 'sample-01' AS message
UNION ALL
SELECT 2, DATE '2026-09-30', 0.20, 20, 'sample-02'
UNION ALL
SELECT 3, DATE '2026-09-30', 0.30, 30, 'sample-03'
UNION ALL
SELECT 4, DATE '2026-09-30', 0.40, 40, 'sample-04'
UNION ALL
SELECT 5, DATE '2026-09-30', 0.50, 50, 'sample-05';
SQL

bq --project_id="$PROJECT_ID" query --use_legacy_sql=false \
  "SELECT * FROM \`${PROJECT_ID}.${DATASET_ID}.${TABLE_ID}\` ORDER BY id"
