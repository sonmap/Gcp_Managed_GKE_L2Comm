#!/usr/bin/env python
# coding: utf-8

"""GKE Autopilot BigQuery test configuration.

Security rules:
- Uses Application Default Credentials (ADC / Workload Identity) only.
- No service-account JSON key path is stored in source.
- Source project defaults are non-sensitive test projects.
- Dataset/table identifiers are supplied at runtime through environment variables.
"""

import os
from google.cloud import bigquery


def _env_bool(name, default=False):
    return os.getenv(name, "1" if default else "0").strip().lower() in {
        "1", "true", "yes", "y", "on"
    }


BQ_JOB_PROJECT = os.getenv("BQ_JOB_PROJECT", "gcp-prod-edp-edge-509423")

BQ_VPSH_SOURCE_PROJECT = os.getenv("BQ_VPSH_SOURCE_PROJECT", "pjt-c-admin")
BQ_VPSH_SOURCE_DATASET = os.getenv("BQ_VPSH_SOURCE_DATASET", "")
BQ_VPSH_SOURCE_TABLE = os.getenv("BQ_VPSH_SOURCE_TABLE", "")

BQ_RKDG_SOURCE_PROJECT = os.getenv("BQ_RKDG_SOURCE_PROJECT", "pjt-c-admin")
BQ_RKDG_SOURCE_DATASET = os.getenv("BQ_RKDG_SOURCE_DATASET", "")
BQ_RKDG_SOURCE_TABLE = os.getenv("BQ_RKDG_SOURCE_TABLE", "")

BQ_PARSE_SOURCE_PROJECT_1 = os.getenv("BQ_PARSE_SOURCE_PROJECT_1", "pjt-c-admin")
BQ_PARSE_SOURCE_DATASET_1 = os.getenv("BQ_PARSE_SOURCE_DATASET_1", "")
BQ_PARSE_SOURCE_TABLE_1 = os.getenv("BQ_PARSE_SOURCE_TABLE_1", "")

BQ_PARSE_SOURCE_PROJECT_2 = os.getenv(
    "BQ_PARSE_SOURCE_PROJECT_2", "gcp-prod-edp-hub-vpchost"
)
BQ_PARSE_SOURCE_DATASET_2 = os.getenv("BQ_PARSE_SOURCE_DATASET_2", "")
BQ_PARSE_SOURCE_TABLE_2 = os.getenv("BQ_PARSE_SOURCE_TABLE_2", "")

BQ_WRITE_PROJECT = os.getenv("BQ_WRITE_PROJECT", BQ_JOB_PROJECT)
BQ_WRITE_DATASET = os.getenv("BQ_WRITE_DATASET", "")
BQ_READ_ONLY = _env_bool("BQ_READ_ONLY", True)

PROJECT_ID = BQ_JOB_PROJECT


def mk_client(project_id=None, **kwargs):
    """Create a BigQuery client using ADC / Workload Identity."""
    return bigquery.Client(project=project_id or BQ_JOB_PROJECT, **kwargs)
