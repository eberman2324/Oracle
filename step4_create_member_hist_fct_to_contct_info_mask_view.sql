create or replace view prod_dw.member_hist_fct_to_contct_info_mask
as
(select /* full(cfi) */
cfi.MEMBER_HISTORY_FACT_KEY, 
case when nvl(masked_ind, 0) = 1  then -99 else CONTACT_INFO_KEY end as CONTACT_INFO_KEY
from prod_dw.member_hist_fct_to_contct_info  cfi
left outer join prod_dw.all_member_history_Fact mhf on cfi.MEMBER_HISTORY_FACT_KEY = MHF.MEMBER_HISTORY_FACT_KEY);