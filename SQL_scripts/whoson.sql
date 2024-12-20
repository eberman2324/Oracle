Doc
*************************************************************************************
Script:         whoson.sql
Title:          Who is on database
Author:         Mark Luddy      8/1996 - 11/2014
Desc:           This script show users who are currently connected to the database.
                It does not show the Oracle deamons acting against the database.

Misc:           This script has successfully executed on 7.3+
*************************************************************************************
#


col time	heading "Time Stamp"        format a20
col osuser	heading "OS user"	format a12
col username	heading "UserName"	format a16
col program	Heading "Program"	format a40
col spid 	heading "SPID"		format a10
col action	heading "Action"	format a20
col module 	heading "Module"	format a45

column SERVICE_NAME 	heading "SERVICE NAME" format a12

set linesize 140

Rem ----- V ----- cut ----- V ----- cut ----- V ----- cut ----- V ----- cut ----- V
set termout off
column timecol new_value timestamp
column spool_extension new_value suffix
SELECT to_char(sysdate,'dd-Mon-yyyy_hh24miss') timecol,'.outt' spool_extension FROM sys.dual;
column output new_value dbname
SELECT value || '_' output FROM v$parameter WHERE name = 'db_name';
set termout on
spool whoson____&&dbname&&timestamp&&suffix
Rem ----- ^ ----- cut ----- ^ ----- cut ----- ^ ----- cut ----- ^ ----- cut ----- ^


select
	substr(to_char(s.logon_time, 'DD-MON-YY HH24:MI:SS'),1,25) time,
	--to_number (p.spid) spid,
	--substr(s.schemaname,1,8) schema,
	substr(s.osuser, 1, 12) osuser,
	substr(s.username, 1,16) username,
	--substr(s.program,1,40) program,
	--p.spid,
	s.sid,
	s.serial#,
	--s.sql_address,
	--s.machine,
	s.status,
	s.service_name,
	s.module
	--s.action
from 
	v$session s, v$process p
where 
	s.paddr = p.addr
	--and s.osuser is not null
	and s.username not like 'oracle%'
order by 
	p.spid, s.status desc, s.osuser
--	s.sid, s.status desc, s.osuser
--	s.status desc, s.osuser, spid
--	s.sid
;

spool off;
exit;
--
--
