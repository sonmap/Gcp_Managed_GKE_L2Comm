#!/usr/bin/env python
# coding: utf-8

"""GKE Autopilot test configuration.

- BigQuery job project, source projects/datasets, and write target are configurable
  through environment variables.
- Uses Application Default Credentials (ADC / Workload Identity) by default.
- If BQ_AUTH_PATH points to an existing JSON key, service-account-file auth is used
  for AS-IS compatibility.
"""

import os
from google.cloud import bigquery
from google.oauth2.service_account import Credentials


def _env_bool(name, default=False):
    return os.getenv(name, "1" if default else "0").strip().lower() in {
        "1", "true", "yes", "y", "on"
    }


BQ_JOB_PROJECT = os.getenv("BQ_JOB_PROJECT", "gcp-prod-edp-edge-509423")

BQ_VPSH_SOURCE_PROJECT = os.getenv("BQ_VPSH_SOURCE_PROJECT", "gcp-prod-edp-lake")
BQ_VPSH_SOURCE_DATASET = os.getenv("BQ_VPSH_SOURCE_DATASET", "DLKL2RSVP")
BQ_RKDG_SOURCE_PROJECT = os.getenv("BQ_RKDG_SOURCE_PROJECT", "gcp-prod-edp-lake")
BQ_RKDG_SOURCE_DATASET = os.getenv("BQ_RKDG_SOURCE_DATASET", "DLKT2RSVP")
BQ_PARSE_SOURCE_PROJECT_1 = os.getenv("BQ_PARSE_SOURCE_PROJECT_1", "gcp-prod-edp-lake")
BQ_PARSE_SOURCE_DATASET_1 = os.getenv("BQ_PARSE_SOURCE_DATASET_1", "DLKVW")
BQ_PARSE_SOURCE_PROJECT_2 = os.getenv("BQ_PARSE_SOURCE_PROJECT_2", "gcp-sbx-edp-rsvp")
BQ_PARSE_SOURCE_DATASET_2 = os.getenv("BQ_PARSE_SOURCE_DATASET_2", "DLKVWE")

BQ_WRITE_PROJECT = os.getenv("BQ_WRITE_PROJECT", BQ_JOB_PROJECT)
BQ_WRITE_DATASET = os.getenv("BQ_WRITE_DATASET", "DLKT2RSVP_TEST")
BQ_READ_ONLY = _env_bool("BQ_READ_ONLY", True)

AUTH_PATH = os.getenv("BQ_AUTH_PATH", "")
PROJECT_ID = BQ_JOB_PROJECT


def mk_client(project_id=None, auth_path=None, **kwargs):
    project_id = project_id or BQ_JOB_PROJECT
    auth_path = auth_path if auth_path is not None else AUTH_PATH

    if auth_path and os.path.isfile(auth_path):
        credentials = Credentials.from_service_account_file(auth_path)
        return bigquery.Client(project=project_id, credentials=credentials, **kwargs)

    return bigquery.Client(project=project_id, **kwargs)
