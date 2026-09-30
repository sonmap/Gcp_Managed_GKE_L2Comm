#!/usr/bin/env python
# coding: utf-8

from config import (
    BQ_JOB_PROJECT,
    BQ_SOURCE_PROJECT,
    BQ_SOURCE_DATASET,
    BQ_SOURCE_TABLE,
    mk_client,
)


def main():
    table_id = f"{BQ_SOURCE_PROJECT}.{BQ_SOURCE_DATASET}.{BQ_SOURCE_TABLE}"

    print(f"JOB_PROJECT={BQ_JOB_PROJECT}")
    print(f"SOURCE_TABLE={table_id}")
    print("AUTH=ADC/Workload Identity")

    client = mk_client()
    try:
        ok = list(client.query("SELECT 1 AS ok").result())[0]["ok"]
        print(f"[OK] query job / SELECT 1 => {ok}")

        table = client.get_table(table_id)
        print(f"[OK] get_table => rows={table.num_rows}")

        query = f"SELECT * FROM `{table_id}` ORDER BY id LIMIT 10"
        rows = list(client.query(query).result())
        print(f"[OK] SELECT sample rows => {len(rows)}")
        for row in rows:
            print(dict(row.items()))
    finally:
        client.close()


if __name__ == "__main__":
    main()
