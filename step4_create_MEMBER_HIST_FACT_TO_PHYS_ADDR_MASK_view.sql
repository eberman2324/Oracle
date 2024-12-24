create or replace view prod_dw.MEMBER_HIST_FACT_TO_PHYS_ADDR_MASK
as
(select MEMBER_ADDRESS_TYPE_KEY,
MHFPA.MEMBER_HISTORY_FACT_KEY,
case  when nvl(masked_ind, 0) = 1  then -99 else	POSTAL_ADDRESS_KEY	end as	POSTAL_ADDRESS_KEY,
SORT_ORDER,
WEIGHT,
MEMBER_HIST_TO_PHYS_ADDR_ID
from prod_dw.MEMBER_HIST_FACT_TO_PHYS_ADDR  MHFPA
left outer join prod_dw.all_member_history_Fact mhf on MHFPA.MEMBER_HISTORY_FACT_KEY = MHF.MEMBER_HISTORY_FACT_KEY);