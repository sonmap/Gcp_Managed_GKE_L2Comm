import os
from google.cloud import bigquery

EXECUTION_PROJECT = os.getenv("EXECUTION_PROJECT", "gcp-prod-edp-edge-509423")
TARGET_PROJECT = os.getenv("TARGET_PROJECT", "pjt-c-admin")
TARGET_DATASET = os.getenv("TARGET_DATASET", "dlk_sample")
TARGET_TABLE = os.getenv("TARGET_TABLE", "gcp_public_sample")


def main() -> None:
    client = bigquery.Client(project=EXECUTION_PROJECT)
    destination = f"{TARGET_PROJECT}.{TARGET_DATASET}.{TARGET_TABLE}"

    sql = """
    SELECT
      word,
      word_count,
      corpus,
      corpus_date,
      CURRENT_TIMESTAMP() AS loaded_at
    FROM `bigquery-public-data.samples.shakespeare`
    ORDER BY word_count DESC
    LIMIT 1000
    """

    job_config = bigquery.QueryJobConfig(
        destination=destination,
        write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,
    )

    print(f"Starting query; destination={destination}")
    job = client.query(sql, job_config=job_config)
    job.result()
    print(f"Completed; rows written={job.num_dml_affected_rows or 'query result'}")


if __name__ == "__main__":
    main()
