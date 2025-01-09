select sum(bytes/1024/1024) as M from dba_segments
where segment_type= 'TABLE' and segment_name IN ( 'T_ACCOUNT_STRUCTURE',
'T_DIS_CLAIM','T_DIS_PLAN','T_DIS_PLAN_VERSION','T_ACCOUNT_STRUCTURE',
'T_ADDRESS',
'T_COMPANY',
'T_COMPANY_PARMS',
'T_DIS_CLAIM',
'T_DIS_CLINICAL',
'T_DIS_FINANCIAL',
'T_DIS_OFFSETS',
'T_DIS_OVERPAYMENT_BALANCE',
'T_DIS_PLAN',
'T_DIS_PLAN_CAT',
'T_DIS_PLAN_SET_DURTN_TIERS',
'T_DIS_PLAN_THRESHOLD',
'T_DIS_PLAN_VALID_OFFSETS',
'T_DIS_PLAN_VARIABLE_DURTN',
'T_DIS_PLAN_VERSION',
'T_DIS_RTW',
'T_DIS_SOCIAL_SECURITY',
'T_EMP_RELATIVE',
'T_EMPLOYEE',
'T_PERSON',
'T_RELATIONSHIP_TYPE',
'T_WKAB_LOOKUP','BENENG_PAYMENT_RQST'
)
and owner IN ('WKAB10','BENENG')


-----------------------------------------------------------------------

select sum(bytes/1024/1024) as M from dba_segments
where segment_type= 'TABLE' and segment_name IN ('T_DIS_CLAIM'
)
and owner IN ('WKAB10')


select count(*) from wkab10.T_DIS_CLAIM
--2947089
select avg(vsize(CLAIM_ID) + vsize(EDIT_DATE) + vsize(CLAIM_STATUS_ID)) from wkab10.T_DIS_CLAIM
--15.2

--15.2 * 2947089 = 44795752 (bytes) = 43 M

--------------------------------------------------------------
