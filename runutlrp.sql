set trimspool on verify off

column owner format a15
column object_name format a30
column object_type format a30

PROMPT
connect / as sysdba

spool &1._compile_invalids_&2..out

PROMPT
PROMPT  Invalid Objects before utlrp.sql
PROMPT  ********************************
select owner,  OBJECT_NAME, object_type from DBA_OBJECTS where status = 'INVALID';
PROMPT
@$ORACLE_HOME/rdbms/admin/utlrp.sql
PROMPT
PROMPT  Invalid Objects after utlrp.sql
PROMPT  ********************************
select owner, OBJECT_NAME, object_type from DBA_OBJECTS where status = 'INVALID';
PROMPT

