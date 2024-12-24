create or replace view PROD_DW.MBR_PHI_LGL_REPRESENTATIV_MASK_FACT
as
(select MBR_PHI_LGL_REP_FACT_KEY	,
MPLRF.MEMBER_HISTORY_FACT_KEY	,
DOCUMENT_RECEIVED_DATE_KEY	,
EFFECTIVE_END_DATE_KEY	,
EFFECTIVE_START_DATE_KEY	,
case when nvl(masked_ind, 0) = 1  then 'XXXXX' else	LAST_NAME	end as	 LAST_NAME	,
case when nvl(masked_ind, 0) = 1  then 'XXXXX' else	MIDDLE_NAME end as	 MIDDLE_NAME,
case when nvl(masked_ind, 0) = 1  then 'XXXXX' else	FIRST_NAME end as	 FIRST_NAME ,
SCOPE	,
HCC_REVIEWER	,
case when nvl(masked_ind, 0) = 1  then 'XXXXX' else NAME_SUFFIX	 end as NAME_SUFFIX		,
PREFIX_CODE	,
PHI_RLTP_TO_MEMBER_KEY	,
MBR_PHI_LGL_REP_TYP_CD_ID	,
nvl (masked_ind, 0) as MASKED_IND
From PROD_DW.MBR_PHI_LGL_REPRESENTATIV_FACT MPLRF
left outer join PROD_DW.all_member_history_Fact mhf on MPLRF.MEMBER_HISTORY_FACT_KEY = MHF.MEMBER_HISTORY_FACT_KEY
);