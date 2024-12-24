create or replace view PROD_DW.MBR_PHI_LGL_RPRSNTV_PHONE_MASK_FACT
as
(select
PHONE_KEY	,
case when nvl(masked_ind, 0) = 1  then 'XXXXX' else PHONE_AREA_CD 	end as	PHONE_AREA_CD	,
CONTACT_TELEPHONE_TYPE_KEY	,
case when nvl(masked_ind, 0) = 1  then 'XXXXX' else PHONE_COUNTRY_CD 	end as	PHONE_COUNTRY_CD	,
case when nvl(masked_ind, 0) = 1  then 'XXXXX' else PHONE_EXT_NBR 	end as PHONE_EXT_NBR		,
case when nvl(masked_ind, 0) = 1  then 'XXXXX' else PHONE_NBR	 	end as PHONE_NBR		,
PHF.MBR_PHI_LGL_REP_FACT_KEY	 
from PROD_DW.MBR_PHI_LGL_RPRSNTV_PHONE_FACT PHF
left outer join PROD_DW.MBR_PHI_LGL_REPRESENTATIV_MASK_FACT REP on PHF.MBR_PHI_LGL_REP_FACT_KEY = REP.MBR_PHI_LGL_REP_FACT_KEY);
