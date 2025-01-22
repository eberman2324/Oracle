set termout off
column timecol                  new_value timestamp
column spool_extension          new_value suffix
SELECT to_char(sysdate,'Mon-dd-yyyy') timecol,'.outt' spool_extension FROM sys.dual;
column thisdb                   new_value dbname
SELECT value || '_' thisdb FROM v$parameter WHERE name = 'db_name';
column thishost                 new_value hostname
select replace(host_name,'.aetna.com','') || '_' thishost from v$instance;
set termout on





set linesize 133
col user form a16
col instance form a16
col grantee form a16
col granted_role form a16
col username form a16
col account_status form a16
spool dba_accounts_&&dbname&&hostname&&timestamp&&suffix.out
select user from dual;
select instance from v$thread;
select grantee,granted_role from dba_role_privs where granted_role='DBA' order by grantee;
select username, account_status from dba_users where username in (select grantee from dba_role_privs where granted_role='DBA'); 
