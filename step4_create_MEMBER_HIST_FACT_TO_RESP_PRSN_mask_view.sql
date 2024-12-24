 create or replace view  prod_dw.MEMBER_HIST_FACT_TO_RESP_PRSN_mask
as
(select /* full(MHFTRP) */
MHFTRP.MEMBER_HISTORY_FACT_KEY, 
case when nvl(masked_ind, 0) = 1  then -99 else RESPONSIBLE_PERSON_KEY end as RESPONSIBLE_PERSON_KEY,
SORT_ORDER,
WEIGHT
from prod_dw.MEMBER_HIST_FACT_TO_RESP_PRSN  MHFTRP
left outer join prod_dw.all_member_history_Fact mhf on MHFTRP.MEMBER_HISTORY_FACT_KEY = MHF.MEMBER_HISTORY_FACT_KEY);