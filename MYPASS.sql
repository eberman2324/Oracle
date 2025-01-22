set echo on
set heading on
set lines 140
set pagesize 100
set verify off
column "email_address"          format a50
column "fullname"               format a30
column "last_name"              format a32
column "first_name"             format a32
column "username"               format a18
column "STATUS"                 format a22
column "Lock"                   format a20
column "Expire"                 format a20
column "Created"                format a20
column "profile"                format a21
column  "instance"              format a14
column  granted_role            format a40
column  grantee                 format a18
column name			format a14

select instance from v$thread;
select (upper(trim('A229515'))) username, instance, case
            when exists (select 1 from dba_users where username = (upper(trim('A229515'))))
            then 'USER EXISTS!'
            else 'USER DOES NOT EXIST!!!!!'
        end as rec_exists
from v$thread;
prompt
prompt Strong:
select username, email_address, last_name, first_name from aedba.strong_users where username = (upper(trim('A229515')));
prompt
prompt Status:
select u.username, SUBSTR(account_status,1,16) "STATUS", TO_CHAR(LOCK_DATE,'MM/DD/YYYY hh:miam') "Lock",
        TO_CHAR(expiry_date,'MM/DD/YYYY hh:miam') "Expire", TO_CHAR(CREATED,'MM/DD/YYYY hh:miam') "Created", profile
from dba_users u
where username =(upper(trim('A229515')))
order by CREATED, username, profile 
;
select name, ptime "Last_Changed" 
from sys.user$
where name =(upper(trim('A229515')));

alter user a229515 account unlock;
alter user a229515 default role all; 
--alter user a229515 identified by Globe#123 ;
--alter user a229515 identified by Hurley#123 ; 
--alter user a229515 identified by Desktop#123 ; 
alter user a229515 identified by Santa#123 ;

