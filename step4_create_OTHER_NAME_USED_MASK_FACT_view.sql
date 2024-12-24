  CREATE OR REPLACE FORCE EDITIONABLE VIEW "PROD_DW"."OTHER_NAME_USED_MASK_FACT" ("OTHER_NM_KEY", "FIRST_NM", "LAST_NM", "MEMBER_HISTORY_FACT_KEY", "MIDDLE_NM", "PREFIX_CD", "OTHER_NM_TYPE_ID") AS 
  (select OTHER_NM_KEY	,
case when nvl(masked_ind, 0) = 1  then 'XXXXX' else  FIRST_NM	end as FIRST_NM	 ,
case when nvl(masked_ind, 0) = 1  then 'XXXXX' else LAST_NM end as  LAST_NM	,
ONUF.MEMBER_HISTORY_FACT_KEY	,
case when nvl(masked_ind, 0) = 1  then 'XXXXX' else  MIDDLE_NM end as MIDDLE_NM 	,
PREFIX_CD	,
OTHER_NM_TYPE_ID	
from prod_dw.OTHER_NAME_USED_FACT  ONUF
left outer join prod_dw.all_member_history_Fact mhf on ONUF.MEMBER_HISTORY_FACT_KEY = MHF.MEMBER_HISTORY_FACT_KEY)
;