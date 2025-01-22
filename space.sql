Doc
*************************************************************************************
Script:		Space_ML.sql
Title:		Space Report
Author: 	Mark Luddy 	8/1996 - 8/2007
Desc:		This script produces a space report of an Oracle database by
		datafile.  It includes the datafiles, Reads/writes, the Table
		Space, a count of the number of tables and indexes in that
		file's tablespace, FSFI (Kevin Loney's Free Space Fragmentation
		Index), percent full, and total size (in meg) allocated, used 
		and free.

		This script was modified to sort by drives (if NT \) and mount
		points (IF unix /)...

		This report was modified to include the auto-extent values on 
		the tablespaces.  What the increment is and what the max is.

Reqs:		This script requires the space_prep.sql script to be executed 
		as sys, and should be executed by a user with DBA privileges.

Misc:		This script has successfully executed on 7.3, 8.0.5, 8.1.5, & 8.1.6
		This script was modified to work with Oracle 9i and 10g.
*************************************************************************************
#


set space 1;
set pagesize 120;
set heading on;
set wrap off;
-- set feedback off;
--set linesize 200
set linesize 185

REM  ********************************************************************************
REM  In the following few lines, if you are on unix change the 'NOTEPAD' to 'vi'...
REM  ********************************************************************************
set term off
set heading off

spool tmp7_spool.sql
	select 'spool '||name||'_'||to_char(sysdate,'mondd_hh24mi')||'.space' 
	from sys.v_$database;
spool off

spool tmp7_vi.sql
	select 'host vi '||name||'_'||to_char(sysdate,'mondd_hh24mi')||'.space' 
	from sys.v_$database;
spool off

@tmp7_spool.sql

set term on
set heading on
REM  ********************************************************************************

col file_name		heading 'File Names'		format a66
col auto_ext_by		heading 'Inc (M)'		format 9999
col max_ext		heading 'MAX (M)'		format 999999
col reads		heading 'RDS'			format 99999999
col writes		heading 'WRTS'			format 99999999
col tablespace_name     heading 'Tb Space'		format a18
col table_count		heading 'T'			format 99999
col index_count		heading 'I'			format 99999
col fsfi		heading 'FSFI'			format 999.99
col percentage_full	heading '% Full'		format a6		just r
col Total_M		heading 'Total M'		format 9,999,999
col Used_M 		heading 'Used M'		format 9,999,999
col Free_M		heading 'Free M'		format 9,999,999
col Total_K		heading 'Total K'		format 9,999,999,999	noprint
col Used_K		heading 'Used K'		format 9,999,999,999	noprint 
col Free_K		heading 'Free K'		format 9,999,999,999	noprint

-- break on report;
break on brk skip 2 on report;
column brk  noprint;

compute sum of Total_M on brk; 
compute sum of Used_M on brk;
compute sum of Free_M on brk;
compute sum of reads on brk; 
compute sum of writes on brk;

compute sum of Total_M on report; 
compute sum of Used_M on report;
compute sum of Free_M on report;
compute sum of reads on report; 
compute sum of writes on report;

SELECT
	substr(t.file_name,1,instr(t.file_name,'/',-1)) brk,
	substr(t.file_name,1,64) file_name,
	(x.inc*8)/1024 auto_ext_by,			-- multiply *8 for 8k block sizes
	(x.maxextend*8)/1024 max_ext,			-- multiply *8 for 8k block sizes
	rw.phyrds reads, 
	rw.phywrts writes,
	substr(t.tablespace_name,1,18) tablespace_name,
	c.table_count,
	c.index_count,
	f.fsfi fsfi,
	substr(round(100 * ((nvl(t.bytes,0) - nvl(f.bytes,0)) / 1024) / (nvl(t.bytes,0) / 1024)),1,10)||'%' percentage_full,
	((nvl(t.bytes,0) / 1024) /1024) Total_M,
	nvl(t.bytes,0) Total_K,
	round((((nvl(t.bytes,0) - nvl(f.bytes,0))/1024) /1024)) used_M,
	nvl(t.bytes,0) - nvl(f.bytes,0) used_K,
	round(((nvl(f.bytes,0) /1024) /1024)) free_M,
	nvl(f.bytes,0) free_K
FROM
	sys.Total t, 
	sys.free f, 
	sys.counts c, 
	v$filestat rw,
	sys.filext$ x
WHERE
	t.tablespace_name = f.tablespace_name(+) AND
	t.file_id = f.file_id(+) AND 
	t.tablespace_name =  c.tablespace_name AND
	t.file_id = rw.file# AND
	t.file_id = x.file#(+)
ORDER BY
	1,2
;

set heading off
set newpage 1
SELECT
	substr(to_char(sysdate, 'DD-MON-YY HH24:MI:SS'),1,25) "Time Stamp",
	substr(instance,1,10) "Oracle SID"
FROM
	v$thread
;

set heading on

spool off;

REM  ********************************************************************************
/* run dynamic editor file */
@tmp7_vi.sql

/* Remove temp spool scripts */
host rm tmp7_*.sql
REM  ********************************************************************************

/* eof */

