#!/usr/bin/env python
# coding: utf-8

"""Read-only BigQuery connectivity/table-access smoke test for GKE Autopilot."""

from config import (
    mk_client,
    PROJECT_ID,
    BQ_JOB_PROJECT,
    BQ_VPSH_SOURCE_PROJECT,
    BQ_VPSH_SOURCE_DATASET,
    BQ_VPSH_SOURCE_TABLE,
    BQ_RKDG_SOURCE_PROJECT,
    BQ_RKDG_SOURCE_DATASET,
    BQ_RKDG_SOURCE_TABLE,
    BQ_PARSE_SOURCE_PROJECT_1,
    BQ_PARSE_SOURCE_DATASET_1,
    BQ_PARSE_SOURCE_TABLE_1,
    BQ_PARSE_SOURCE_PROJECT_2,
    BQ_PARSE_SOURCE_DATASET_2,
    BQ_PARSE_SOURCE_TABLE_2,
    BQ_READ_ONLY,
)


def _table_id(project, dataset, table):
    if not dataset or not table:
        return None
    return f"{project}.{dataset}.{table}"


def main():
    tables = [
        ("VPSH", _table_id(
            BQ_VPSH_SOURCE_PROJECT, BQ_VPSH_SOURCE_DATASET, BQ_VPSH_SOURCE_TABLE
        )),
        ("RKDG", _table_id(
            BQ_RKDG_SOURCE_PROJECT, BQ_RKDG_SOURCE_DATASET, BQ_RKDG_SOURCE_TABLE
        )),
        ("PARSE-1", _table_id(
            BQ_PARSE_SOURCE_PROJECT_1,
            BQ_PARSE_SOURCE_DATASET_1,
            BQ_PARSE_SOURCE_TABLE_1,
        )),
        ("PARSE-2", _table_id(
            BQ_PARSE_SOURCE_PROJECT_2,
            BQ_PARSE_SOURCE_DATASET_2,
            BQ_PARSE_SOURCE_TABLE_2,
        )),
    ]

    print(f"JOB_PROJECT={BQ_JOB_PROJECT}")
    print(f"READ_ONLY={BQ_READ_ONLY}")
    print("AUTH=ADC/Workload Identity")

    client = mk_client(PROJECT_ID)
    try:
        v = list(client.query("SELECT 1 AS ok").result())[0]["ok"]
        print(f"[OK] query job / SELECT 1 => {v}")

        for label, table_id in tables:
            if not table_id:
                print(f"[SKIP] {label}: dataset/table not supplied")
                continue
            try:
                table = client.get_table(table_id)
                print(f"[OK] {label}: {table_id} rows={table.num_rows}")
            except Exception as exc:
                print(
                    f"[FAIL] {label}: {table_id}: "
                    f"{type(exc).__name__}: {exc}"
                )
    finally:
        client.close()


if __name__ == "__main__":
    main()
