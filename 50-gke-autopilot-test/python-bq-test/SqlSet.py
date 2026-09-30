#!/usr/bin/env python
# coding: utf-8

from config import (
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
)


class SqlSet:
    def __init__(self, project_id_nm=None):
        self.project_id_nm = project_id_nm
        self.vpsh_inf_input_tbl_nm = 'L2VP_VPSH_ANAL_MART_H'
        self.vpsh_inf_rslt_tmp_01_tbl_nm = 'L2VP_VPSH_SUSP_PBBL_MART_H_01_TMP'
        self.vpsh_risk_inf_input_tbl_nm = 'L2VP_RKDG_CALL_SMS_TRAIN_MART_TMP'
        self.vpsh_risk_inf_rslt_tmp_01_tbl_nm = 'L2VP_VPSH_PHCL_RKDG_H_01_TMP'
        self.vpsh_parse_input_01_tbl_nm = 'LOHW_TB_VPSH_DCL_INFO'
        self.vpsh_parse_input_02_tbl_nm = 'LOHW_TB_VPSH_DCL_INFO_CZ'
        self.vpsh_parse_rslt_tmp_01_tbl_nm = 'L2VP_VPSH_DCL_INFO_01_TMP'

    def fn_get_query_vpsh_inference_data(self, features, row_start, row_end, var_yyyymmdd):
        return f"""
            with temp_01 as (
                select p_yyyymmdd, {features},
                       row_number() over (order by dsp_tlno asc) as rn
                from `{BQ_VPSH_SOURCE_PROJECT}.{BQ_VPSH_SOURCE_DATASET}.{self.vpsh_inf_input_tbl_nm}`
                where p_yyyymmdd = parse_date('%Y%m%d', '{var_yyyymmdd}')
            )
            select p_yyyymmdd, {features}, rn
            from temp_01
            where rn between {row_start} and {row_end}
        """

    def fn_get_query_rkdg_inference_data(self, features, row_start, row_end):
        return f"""
            with temp_01 as (
                select {features},
                       row_number() over (order by base_cust_tlno asc) as rn
                from `{BQ_RKDG_SOURCE_PROJECT}.{BQ_RKDG_SOURCE_DATASET}.{self.vpsh_risk_inf_input_tbl_nm}`
            )
            select {features}, rn
            from temp_01
            where rn between {row_start} and {row_end}
        """

    def fn_get_query_parse_input_data(self, var_yyyymmdd):
        return f"""
            select a1.dcl_dttm, a2.msg_cntn
            from `{BQ_PARSE_SOURCE_PROJECT_1}.{BQ_PARSE_SOURCE_DATASET_1}.{self.vpsh_parse_input_01_tbl_nm}` a1
            left join `{BQ_PARSE_SOURCE_PROJECT_2}.{BQ_PARSE_SOURCE_DATASET_2}.{self.vpsh_parse_input_02_tbl_nm}` a2
              on a2.cz_lnk_key = a1.cz_lnk_key
            where parse_date('%Y%m%d', left(a1.dcl_dttm, 8)) >=
                  date_sub(parse_date('%Y%m%d', '{var_yyyymmdd}'), interval 7 day)
        """

    def fn_drop_tmp_table(self, drop_table_nm):
        return f"""
            drop table if exists `{BQ_WRITE_PROJECT}.{BQ_WRITE_DATASET}.{drop_table_nm}`
        """
