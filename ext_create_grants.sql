spool create_grants.sql

set echo off feedback off verify off
set trimspool on head off line 200

prompt set echo off feedback off termout off
prompt set verify off SQLBLANKLINES on
prompt set trimspool on head on
prompt
prompt spool create_dw_grants_&2..out
prompt

prompt select name DBNAME, to_char(sysdate, 'MM-DD-YYYY HH:MI:SS AM') "StartTime" from v$database;;
prompt
prompt set head off echo on feed on

select 'grant select on '||owner||'.'||object_name||' to APP_USER_ROLE,S060331,AE_CUSTOM;'
from dba_objects
where owner in ('PROD_DW')
and   object_type in ('TABLE','VIEW','MATERIALIZED VIEW')
and   object_name not like 'BIN$%'
and   created > sysdate - &1
and   object_name not in
(
'ALL_ACCOUNT_HISTORY_FACT',
'ALL_AUTH_FACT',
'ALL_MEMBER_VERSION_HIST_FACT',
'MBR_PHI_LGL_REPRESENTATIV_FACT',
'MEMBER_HIST_FCT_TO_CONTCT_INFO',
'MEMBER_HIST_FACT_TO_PHYS_ADDR',
'MBR_PHI_LGL_RPRSNTV_PHONE_FACT',
'PREMIUM_PAYMENT_ROSTER_FACT',
'OTHER_NAME_USED_FACT',
'MEMBER_HIST_FACT_TO_RESP_PRSN'
)
union all
select 'grant select on '||owner||'.'||object_name||' to APP_USER_ROLE,S060331,PROD_DW;'
from dba_objects
where owner in ('AE_CUSTOM')
and   object_type in ('TABLE','VIEW','MATERIALIZED VIEW')
and   object_name not like 'BIN$%'
and   created > sysdate - &1
order by 1;

prompt
prompt set head on echo off feed off
prompt
prompt select to_char(sysdate, 'MM-DD-YYYY HH:MI:SS AM') "EndTime" from dual;;
prompt
prompt spool off
prompt
 
spool off

