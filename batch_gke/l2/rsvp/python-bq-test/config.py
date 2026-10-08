#!/usr/bin/env python
# coding: utf-8

"""Sanitized BigQuery smoke-test configuration.

No customer-specific dataset/table names, credentials, or legacy storage paths are
stored in this source. Authentication uses ADC / Workload Identity.
"""

import os
from google.cloud import bigquery

BQ_JOB_PROJECT = os.getenv("BQ_JOB_PROJECT", "gcp-prod-edp-edge-509423")
BQ_SOURCE_PROJECT = os.getenv("BQ_SOURCE_PROJECT", "pjt-c-admin")
BQ_SOURCE_DATASET = os.getenv("BQ_SOURCE_DATASET", "l2comm_test")
BQ_SOURCE_TABLE = os.getenv("BQ_SOURCE_TABLE", "sample_input")


def mk_client(project_id=None):
    return bigquery.Client(project=project_id or BQ_JOB_PROJECT)
