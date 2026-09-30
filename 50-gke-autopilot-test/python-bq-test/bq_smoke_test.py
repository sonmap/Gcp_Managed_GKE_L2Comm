#!/usr/bin/env python
# coding: utf-8

"""Read-only BigQuery connectivity/table-access smoke test for GKE Autopilot."""

from config import (
    mk_client,
    PROJECT_ID,
    AUTH_PATH,
    BQ_JOB_PROJECT,
    BQ_VPSH_SOURCE_PROJECT,
    BQ_VPSH_SOURCE_DATASET,
    BQ_RKDG_SOURCE_PROJECT,
    BQ_RKDG_SOURCE_DATASET,
    BQ_PARSE_SOURCE_PROJECT_1,
    BQ_PARSE_SOURCE_DATASET_1,
    BQ_PARSE_SOURCE_PROJECT_2,
    BQ_PARSE_SOURCE_DATASET_2,
    BQ_WRITE_PROJECT,
    BQ_WRITE_DATASET,
    BQ_READ_ONLY,
)
from SqlSet import SqlSet


def main():
    sql = SqlSet(PROJECT_ID)
    tables = [
        ("VPSH", f"{BQ_VPSH_SOURCE_PROJECT}.{BQ_VPSH_SOURCE_DATASET}.{sql.vpsh_inf_input_tbl_nm}"),
        ("RKDG", f"{BQ_RKDG_SOURCE_PROJECT}.{BQ_RKDG_SOURCE_DATASET}.{sql.vpsh_risk_inf_input_tbl_nm}"),
        ("PARSE-1", f"{BQ_PARSE_SOURCE_PROJECT_1}.{BQ_PARSE_SOURCE_DATASET_1}.{sql.vpsh_parse_input_01_tbl_nm}"),
        ("PARSE-2", f"{BQ_PARSE_SOURCE_PROJECT_2}.{BQ_PARSE_SOURCE_DATASET_2}.{sql.vpsh_parse_input_02_tbl_nm}"),
    ]

    print(f"JOB_PROJECT={BQ_JOB_PROJECT}")
    print(f"WRITE_TARGET={BQ_WRITE_PROJECT}.{BQ_WRITE_DATASET}")
    print(f"READ_ONLY={BQ_READ_ONLY}")
    print(f"AUTH={'JSON:' + AUTH_PATH if AUTH_PATH else 'ADC/Workload Identity'}")

    client = mk_client(PROJECT_ID, AUTH_PATH)
    try:
        v = list(client.query("SELECT 1 AS ok").result())[0]["ok"]
        print(f"[OK] query job / SELECT 1 => {v}")

        for label, table_id in tables:
            try:
                table = client.get_table(table_id)
                print(f"[OK] {label}: {table_id} rows={table.num_rows}")
            except Exception as exc:
                print(f"[FAIL] {label}: {table_id}: {type(exc).__name__}: {exc}")
    finally:
        client.close()


if __name__ == "__main__":
    main()
