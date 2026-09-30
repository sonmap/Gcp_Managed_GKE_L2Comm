#!/usr/bin/env python
# coding: utf-8

"""Environment-driven SQL builder for the Autopilot test.

No business-specific project, dataset, or table names are hard-coded.
"""

from config import (
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
    BQ_WRITE_PROJECT,
    BQ_WRITE_DATASET,
)


def _required(name, value):
    if not value:
        raise ValueError(
            f"{name} is not set. Supply it as a runtime environment variable."
        )
    return value


class SqlSet:
    def __init__(self, project_id_nm=None):
        self.project_id_nm = project_id_nm
        self.vpsh_inf_input_tbl_nm = BQ_VPSH_SOURCE_TABLE
        self.vpsh_risk_inf_input_tbl_nm = BQ_RKDG_SOURCE_TABLE
        self.vpsh_parse_input_01_tbl_nm = BQ_PARSE_SOURCE_TABLE_1
        self.vpsh_parse_input_02_tbl_nm = BQ_PARSE_SOURCE_TABLE_2

    def fn_get_query_vpsh_inference_data(
        self, features, row_start, row_end, var_yyyymmdd
    ):
        dataset = _required("BQ_VPSH_SOURCE_DATASET", BQ_VPSH_SOURCE_DATASET)
        table = _required("BQ_VPSH_SOURCE_TABLE", self.vpsh_inf_input_tbl_nm)
        return f"""
            with temp_01 as (
                select p_yyyymmdd, {features},
                       row_number() over (order by dsp_tlno asc) as rn
                from `{BQ_VPSH_SOURCE_PROJECT}.{dataset}.{table}`
                where p_yyyymmdd = parse_date('%Y%m%d', '{var_yyyymmdd}')
            )
            select p_yyyymmdd, {features}, rn
            from temp_01
            where rn between {row_start} and {row_end}
        """

    def fn_get_query_rkdg_inference_data(self, features, row_start, row_end):
        dataset = _required("BQ_RKDG_SOURCE_DATASET", BQ_RKDG_SOURCE_DATASET)
        table = _required("BQ_RKDG_SOURCE_TABLE", self.vpsh_risk_inf_input_tbl_nm)
        return f"""
            with temp_01 as (
                select {features},
                       row_number() over (order by base_cust_tlno asc) as rn
                from `{BQ_RKDG_SOURCE_PROJECT}.{dataset}.{table}`
            )
            select {features}, rn
            from temp_01
            where rn between {row_start} and {row_end}
        """

    def fn_get_query_parse_input_data(self, var_yyyymmdd):
        ds1 = _required("BQ_PARSE_SOURCE_DATASET_1", BQ_PARSE_SOURCE_DATASET_1)
        tb1 = _required("BQ_PARSE_SOURCE_TABLE_1", self.vpsh_parse_input_01_tbl_nm)
        ds2 = _required("BQ_PARSE_SOURCE_DATASET_2", BQ_PARSE_SOURCE_DATASET_2)
        tb2 = _required("BQ_PARSE_SOURCE_TABLE_2", self.vpsh_parse_input_02_tbl_nm)
        return f"""
            select a1.dcl_dttm, a2.msg_cntn
            from `{BQ_PARSE_SOURCE_PROJECT_1}.{ds1}.{tb1}` a1
            left join `{BQ_PARSE_SOURCE_PROJECT_2}.{ds2}.{tb2}` a2
              on a2.cz_lnk_key = a1.cz_lnk_key
            where parse_date('%Y%m%d', left(a1.dcl_dttm, 8)) >=
                  date_sub(parse_date('%Y%m%d', '{var_yyyymmdd}'), interval 7 day)
        """

    def fn_drop_tmp_table(self, drop_table_nm):
        dataset = _required("BQ_WRITE_DATASET", BQ_WRITE_DATASET)
        return f"""
            drop table if exists `{BQ_WRITE_PROJECT}.{dataset}.{drop_table_nm}`
        """
