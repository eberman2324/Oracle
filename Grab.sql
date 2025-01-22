--
-- SQL to "grab" source code out of database
-- Remember to use	 :%s /\s\+$//g  	after to remove all trailing spaces ;-)
-- -------------------------------------------------------------------------------------------------
-- MCL 	7/2016
-- Modified July 27th 2017 (M.Luddy
-- -------------------------------------------------------------------------------------------------

set lines 165
set pagesize 0
set heading off
set verify off
set feedback off

-- accept CODENAME      Prompt  "Name  of code :"
-- accept CODEOWNER      Prompt "Owner of code :"

Rem ----- V ----- cut ----- V ----- cut ----- V ----- cut ----- V ----- cut ----- V
set termout off
column thiscode         new_value NEWCODENAME
--SELECT '&&1'||'__' thiscode from dual;
SELECT rpad ('&&1',35,'_') thiscode from dual;
column timecol new_value timestamp
column spool_extension new_value suffix
SELECT to_char(sysdate,'dd-Mon-yyyy_hh24miss') timecol,'.plsql' spool_extension FROM sys.dual;
column output new_value dbname
SELECT value || '_' output FROM v$parameter WHERE name = 'db_name';
set termout on
--spool create___&&NEWCODENAME&&dbname&&timestamp&&suffix
spool create___&&NEWCODENAME&&timestamp&&suffix
Rem ----- ^ ----- cut ----- ^ ----- cut ----- ^ ----- cut ----- ^ ----- cut ----- ^

select 'set echo on ' from dual;
select 'show user' from dual;
select '-- Remember to use       :%s /\s\+$//g          after to remove all trailing spaces ;-) ' from dual;
prompt
select 'alter session set current_schema=AE_CUSTOM; ' from dual;
prompt
--select 'spool create_'||'&&1'||'_${ORACLE_SID}.out' from dual;
select 'spool create___'||'&&NEWCODENAME'||'_${ORACLE_SID}.out' from dual;
prompt
select 'select sys_context(''USERENV'',''SESSION_SCHEMA'') CURRENT_SCHEMA FROM DUAL;' FROM DUAL;
prompt
prompt
select 'create or replace' from dual;

select text
  from dba_source
where name = upper('&&1') and owner = upper('&&2')
order by owner, type, line;

select '/' from dual;
prompt
prompt
SELECT 'show errors;  ' from dual;
prompt
prompt
select 'spool off; ' from dual;

spool off;
exit;  
--
