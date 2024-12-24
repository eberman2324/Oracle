create or replace view prod_Dw.PREMIUM_PAYMENT_ROSTER_MASK_FACT
as
(select PREMIUM_PAYMENT_ROSTER_KEY	,
PRF.ACCOUNT_KEY	,
AMOUNT	,
BENEFIT_PLAN_KEY	,
BILLING_CATEGORY_KEY	,
COMMENTS	,
DO_NOT_RECONCILE_FLAG	,
ENTRY_TIME	,
ENTRY_USER_ID	,
case  when nvl(masked_ind, 0) = 1   then -9223372036854775809 else	MEMBER_BIRTH_DATE_KEY	end as	MEMBER_BIRTH_DATE_KEY	,
case  when nvl(masked_ind, 0) = 1   then 'XXXXX' else	MEMBER_FIRST_NAME	end as	MEMBER_FIRST_NAME	,
case  when nvl(masked_ind, 0) = 1   then 'XXXXX' else	MEMBER_FULL_NAME	end as MEMBER_FULL_NAME	,
MEMBER_KEY	,
case  when nvl(masked_ind, 0) = 1   then 'XXXXX' else	MEMBER_LAST_NAME	end as	MEMBER_LAST_NAME	,
PAYMENT_ROSTER_REASON_KEY	,
PAYMENT_ROSTER_TYPE_CODE	,
BENEFIT_PLAN_TYPE_KEY	,
PREM_PYMNT_BATCH_ENTRY_NBR	,
PREMIUM_PAYMENT_FACT_KEY	,
START_DATE_KEY	,
case  when nvl(masked_ind, 0) = 1   then -9223372036854775809 else SUBSCRIBER_BIRTH_DATE_KEY	 end as SUBSCRIBER_BIRTH_DATE_KEY,
case  when nvl(masked_ind, 0) = 1   then 'XXXXX' else SUBSCRIBER_FIRST_NAME end as SUBSCRIBER_FIRST_NAME	,
case  when nvl(masked_ind, 0) = 1   then 'XXXXX' else SUBSCRIBER_FULL_NAME end as	 SUBSCRIBER_FULL_NAME,
case  when nvl(masked_ind, 0) = 1   then 'XXXXX' else SUBSCRIBER_LAST_NAME end as  SUBSCRIBER_LAST_NAME 	,
SUBSCRIPTION_HCC_ID	,
SUBSCRIPTION_KEY	,
THROUGH_DATE_KEY	,
ACCOUNT_HCC_ID	,
BENEFIT_PLAN_HCC_ID	,
EXCHANGE_ID_TYPE	,
ORG_NAME	,
PAYMENT_TRANSACT_TYPE	,
SUBSCRIBER_HCC_ID	,
SUBSCRIBER_ID	,
TENANT_ID	
from prod_Dw.PREMIUM_PAYMENT_ROSTER_FACT PRF
left outer join    (select account_key,  masked_ind from 
  PROD_DW.ACCOUNT_HISTORY_FACT ) mal 
      on  mal.account_key = PRF.account_key
);