Doc
*************************************************************************************
Script:         whoson.sql
Title:          Who is on database
Author:         Mark Luddy      8/1996 - 11/2000
Desc:           This script show users who are currently connected to the database.
                It does not show the Oracle deamons acting against the database.

Reqs:           N/A

Misc:           This script has successfully executed on 7.3, 8.0.5, 8.1.5, & 8.1.6
*************************************************************************************
#


col time	heading "Time Stamp"        format a20
col osuser	heading "OS user"	format a12
col username	heading "UserName"	format a16
col program	Heading "Program"	format a40
col spid 	heading "SPID"		format a10
col action	heading "Action"	format a20
col module 	heading "Module"	format a50

column SERVICE_NAME 	heading "SERVICE NAME" format a12


set linesize 175
set linesize 155

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
	and s.service_name not like '%_APP'
order by 
	p.spid, s.status desc, s.osuser
--	s.sid, s.status desc, s.osuser
--	s.status desc, s.osuser, spid
--	s.sid
;

