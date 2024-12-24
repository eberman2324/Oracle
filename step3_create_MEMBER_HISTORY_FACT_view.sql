create or replace view PROD_DW.MEMBER_HISTORY_FACT
as
(  
      select MEMBER_HISTORY_FACT_KEY	,
			AMVHF.ACCOUNT_KEY	,
			ANNUAL_WAGE_AMOUNT	,
			AUDIT_LOG_KEY	,
case  when nvl(masked_ind, 0) = 1   then -9223372036854775809 else	MEMBER_BIRTH_DATE_KEY	end as	MEMBER_BIRTH_DATE_KEY	,
case  when nvl(masked_ind, 0) = 1  then -99 else	MEMBER_MAILING_ADDRESS_KEY	end as	MEMBER_MAILING_ADDRESS_KEY	,
			MEMBER_HISTORY_FACT_COUNT	,
case  when nvl(masked_ind, 0) = 1   then -9223372036854775809 else	MEMBER_DEATH_DATE_KEY	end as	MEMBER_DEATH_DATE_KEY	,
			DISABILITY_DENIAL_REASON	,
			DISABILITY_DIAG	,
			DISABILITY_TYPE_CODE	,
			DISABILITY_REPORTED_DATE_KEY	,
			DISABILITY_VERIF_RCPT_DATE_KEY	,
			MEMBER_EFFECTIVE_DATE_KEY	,
case  when nvl(masked_ind, 0) = 1   then 'XXXXX' else	EMAIL_ADDRESS	end as	EMAIL_ADDRESS	,
			EMPLOYEE_TYPE_KEY	,
			EMPLOYMENT_STATUS_KEY	,
			FIRST_EFFECTIVE_DATE_KEY	,
			HEAD_OF_HOUSE_INDIVIDUAL_KEY	,
			HIRE_DATE_KEY	,
			UNITS_HOURS_INTV_KEY	,
			HOURS_WORKED	,
			IMMIGRATION_STATUS_TYPE_KEY	,
			INFORMATION_SOURCE_TYPE_KEY	,
			IS_IN_UNION	,
			IS_MEMBER_IN_HOSPICE	,
			IS_VIP	,
case  when nvl(masked_ind, 0) = 1   then 'XXXXX' else	MEMBER_FIRST_NAME	end as	MEMBER_FIRST_NAME	,
			MEMBER_HCC_ID	,
			MEMBER_KEY	,
case  when nvl(masked_ind, 0) = 1   then 'XXXXX' else	MEMBER_LAST_NAME	end as	MEMBER_LAST_NAME	,
			MARITAL_STATUS_CODE	,
case  when nvl(masked_ind, 0) = 1   then 'XXXXX' else	MEMBER_MIDDLE_NAME	end as	MEMBER_MIDDLE_NAME	,
case  when nvl(masked_ind, 0) = 1   then 'XXXXX' else	MEMBER_FULL_NAME	end as	MEMBER_FULL_NAME	,
case  when nvl(masked_ind, 0) = 1   then 'XXXXX' else	MEMBER_NAME_PREFIX	end as	MEMBER_NAME_PREFIX	,
case  when nvl(masked_ind, 0) = 1   then 'XXXXX' else	MEMBER_NAME_SUFFIX	end as	MEMBER_NAME_SUFFIX	,
			MEMBER_RECEIPT_DATE_KEY	,
case  when nvl(masked_ind, 0) = 1   then 'XXXXX' else	TELEPHONE_NUMBER	end as	TELEPHONE_NUMBER	,
			PRIOR_COVERAGE_MONTH_COUNT	,
			RLTP_TO_SUBSCRIBER_KEY	,
case  when nvl(masked_ind, 0) = 1   then -99 else	MEMBER_HOME_ADDRESS_KEY	end as	MEMBER_HOME_ADDRESS_KEY	,
			RETIREMENT_DATE_KEY	,
			SALARY_GRADE_KEY	,
			SALARY_INTERVAL	,
			SMOKING_STATUS	,
			MEMBER_STATUS	,
			GRADUATION_DATE_KEY	,
			SCHOOL_NAME	,
			SCHOOL_TYPE	,
			STUDENT_STATUS_CODE	,
case  when nvl(masked_ind, 0) = 1   then 'XXXXX' else	SUBSCRIBER_FIRST_NAME	end as	SUBSCRIBER_FIRST_NAME	,
case  when nvl(masked_ind, 0) = 1   then 'XXXXX' else	SUBSCRIBER_LAST_NAME	end as	SUBSCRIBER_LAST_NAME	,
case  when nvl(masked_ind, 0) = 1   then 'XXXXX' else	SUBSCRIBER_MIDDLE_NAME	end as	SUBSCRIBER_MIDDLE_NAME	,
case  when nvl(masked_ind, 0) = 1   then 'XXXXX' else	SUBSCRIBER_FULL_NAME	end as	SUBSCRIBER_FULL_NAME	,
case  when nvl(masked_ind, 0) = 1   then 'XXXXX' else	SUBSCRIBER_NAME_PREFIX	end as	SUBSCRIBER_NAME_PREFIX	,
case  when nvl(masked_ind, 0) = 1   then 'XXXXX' else	SUBSCRIBER_NAME_SUFFIX	end as	SUBSCRIBER_NAME_SUFFIX	,
case  when nvl(masked_ind, 0) = 1   then 'XXXXX' else	SUBSCRIBER_TAX_ID	end as	SUBSCRIBER_TAX_ID	,
			SUBSCRIPTION_HCC_ID	,
			SUBSCRIPTION_KEY	,
			SUBSCRIPTION_RECEIPT_DATE_KEY	,
case  when nvl(masked_ind, 0) = 1   then 'XXXXX' else	TAX_ID	end as	TAX_ID	,
			MEMBER_TERMINATION_DATE_KEY	,
			TITLE	,
			VERSION_EFF_DATE_KEY	,
			VERSION_EXP_DATE_KEY	,
			VIP_REASON_KEY	,
			WAIVE_PHI_CLAIM_RESTRICTION	,
			MEMBER_GENDER_CODE	,
			NATIVE_LANGUAGE_CODE	,
			PRIMARY_LANGUAGE_CODE	,
			DOCUMENT_DELIVERY_METHOD_KEY	,
			CONTACT_METHOD_CODE	,
			EMAIL_FORMAT_KEY	,
			IS_HANDICAPPED	,
			ALT_PAYMENT_RECIPIENT_ADDR_KEY	,
case when  nvl(masked_ind, 0) = 1    then 'XXXXX' else	ALT_PMT_RECIPIENT_FIRST_NAME	end as	ALT_PMT_RECIPIENT_FIRST_NAME	,
case  when nvl(masked_ind, 0) = 1   then 'XXXXX' else	ALT_PMT_RECIPIENT_MIDDLE_NAME	end as	ALT_PMT_RECIPIENT_MIDDLE_NAME	,
case  when nvl(masked_ind, 0) = 1   then 'XXXXX' else	ALT_PMT_RECIPIENT_LAST_NAME	end as	ALT_PMT_RECIPIENT_LAST_NAME	,
case  when nvl(masked_ind, 0) = 1   then 'XXXXX' else	ALT_PMT_RECIPIENT_FULL_NAME	end as	ALT_PMT_RECIPIENT_FULL_NAME	,
case  when nvl(masked_ind, 0) = 1   then 'XXXXX' else	ALT_PMT_RECIPIENT_NAME_PREFIX	end as	ALT_PMT_RECIPIENT_NAME_PREFIX	,
case  when nvl(masked_ind, 0) = 1   then 'XXXXX' else	ALT_PMT_RECIPIENT_NAME_SUFFIX	end as	ALT_PMT_RECIPIENT_NAME_SUFFIX	,
			PAYEE_HCC_ID	,
			PRE_REDUCTION_START_DATE_KEY	,
			PRE_REDUCTION_END_DATE_KEY	,
			PRE_REDUCTION_REASON	,
			PRE_RED_REASON_RECPT_DATE_KEY	,
			ATTACHMENT_SET_ID	,
			DEPARTMENT_KEY	,
			ENDOR_EFF_DATE	,
			ENDOR_EXP_DATE , 
            GENDER_AT_BIRTH_KEY,
            SEXUAL_ORIENTATION_KEY,
            GENDER_IDENTITY_KEY,
           PRONOUNS_KEY,
      nvl(MAL.masked_ind, 0) as MASKED_IND
from prod_dw.ALL_MEMBER_VERSION_HIST_FACT  AMVHF
left outer join    (select distinct account_key,  masked_ind from 
  PROD_DW.ACCOUNT_HISTORY_FACT ) mal 
      on  mal.account_key = AMVHF.account_key
where MEMBER_STATUS in ('a','t','p','u') and (ENDOR_EXP_DATE > SYSDATE OR ENDOR_EXP_DATE is null) 
);