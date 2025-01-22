#!/bin/ksh
# -----------------------------------------------------------
#    File: runsql.ksh
#  Author: Mark Lantsberger  09/28/2000
# Purpose: A KORN shell script to load various functions 
#          for running SQL. For Oracle use.
# Info:    This script belongs in the $SCRIPTS directory.
#          A requirement for this scripts functionality is that an externally
#          authenticated id be created in the database with the name the same
#          as the service id for the oracle rdbms for example "oracle".  If the
#          OS_AUTHENT_PREFIX="" parameter is not present in the init.ora file then
#          the externally authenticated id must have "OPS$" before the name for 
#          example "OPS$ORACLE".

#CREATE USER OPS$ORACLE IDENTIFIED EXTERNALLY
#    DEFAULT TABLESPACE SYSTEM
#    TEMPORARY TABLESPACE TEMP
#    QUOTA UNLIMITED ON SYSTEM
#    QUOTA UNLIMITED ON TEMP
#    PROFILE DEFAULT
#    ACCOUNT UNLOCK
#/
#GRANT "CONNECT" TO OPS$ORACLE
#/
#GRANT DBA TO OPS$ORACLE
#/
#GRANT "RESOURCE" TO OPS$ORACLE
#/
#ALTER USER OPS$ORACLE DEFAULT ROLE "CONNECT",
#                               DBA,
#                               "RESOURCE"
#/
#GRANT CREATE TABLE TO OPS$ORACLE
#/
#GRANT CREATE TABLESPACE TO OPS$ORACLE
#/
#GRANT DROP TABLESPACE TO OPS$ORACLE
#/
#GRANT SELECT ANY TABLE TO OPS$ORACLE
#/
#GRANT UNLIMITED TABLESPACE TO OPS$ORACLE
#/
#
#
#                         C H A N G E S
#
# ----------------------------------------------------------
# 
# For change information see comment in PVCS
# 
#                          
#                          
    
USAGE="Usage: runsql_lib.ksh arg1 (arg1=ORACLE_SID)"

if [ $1 ]
then
    ORACLE_SID=$1
else
    echo $USAGE
    return
fi

####. $HOME/setup_env.ksh $ORACLE_SID ### to be removed

#echo "Starting Load of SQL Library functions... "

############################################################
####  GENERIC UTILITY FUNCTIONS
############################################################

function setup_environment
{

    ### Determine platform script is running on
#    if [ "`uname -m`" = "sun4u" ] ; then
#       ORATAB=`find /var -name oratab -print 2> /dev/null`
#    else
#       ORATAB=`find /etc -name oratab -print 2> /dev/null`
#    fi
ORATAB=/etc/oratab

#    Determine scripts location from oratab file
     export FS_FOR_SCRIPTS=`awk -F: "/${ORACLE_SID}:/ {print \\$4}" $ORATAB 2>/dev/null`
#export FS_FOR_SCRIPTS=/u35

    ### Determine scripts locaation from oratab file
#    cat $ORATAB | while read LINE
#    do
#        case $LINE in
#            \#*)            ;;      #comment-line in oratab
#            *)
#            ORATAB_SID=`echo $LINE | awk -F: '{print $1}' -`
#            if [ "$ORATAB_SID" = '*' ] ; then
#                   ORATAB_SID=""
#            fi
#
#            if [ "$ORACLE_SID" = "$ORATAB_SID" ] ; then
    #          Get Script Path from oratab file.
#               FS_FOR_SCRIPTS=`echo $LINE | awk -F: '{print $4}' -`
#            fi
#        ;;
#        esac
#    done

    export SCRIPTS=$FS_FOR_SCRIPTS/aetna/scripts
    
    echo $SCRIPTS 
    . $SCRIPTS/setupenv.ksh $ORACLE_SID

return $?

}  # end setup_environment


### Setup the environment
setup_environment


###-------------------------------------------------------------------------------------
function output_var
{
   USAGE="Usage: output_export arg1  (arg1=spool output file)"

   if test "$#" -lt 1
   then
     echo $USAGE
     return 1
   fi

   outfile=$1

   export OUTPUT=$SCRIPTS/out/$outfile

return $?

}

###-------------------------------------------------------------------------------------
function mailit_or_not
{
   USAGE="Usage: mailit_or_not arg1 arg2 (arg1=message,arg2=mailing list)"

   if test "$#" -lt 2
   then
     echo $USAGE
     return 1
   fi

   message=$1
   mailist=$2

   typeset -i DebugLevel
   if [[ $DebugLevel == 9 ]]
   then
      set -o xtrace
   else
      set +o xtrace
   fi 

   if [ $mailist == "no_route_print" ]
   then
      echo "Report Output: " $OUTPUT
      read
   else
      MailIt "$message" $OUTPUT $mailist email
      if [ -f $OUTPUT ]
      then
         rm $OUTPUT
      fi 
   fi 

return $?
}

###-------------------------------------------------------------------------------------
function remove_file
{
   USAGE="Usage: remove_file arg1  (arg1=erase file name)"

   if test "$#" -lt 1
   then
     echo $USAGE
     return 1
   fi

   filename=$1

   # Check if xtrace debugging should be started
   typeset -i DebugLevel
   if [[ $DebugLevel == 9 ]]
   then
      set -o xtrace
   else
      set +o xtrace
   fi 

   # Check for override of file removal
   if [[ $NoRemoveFile == "9" ]]
   then
      echo "File not removed: " $filename
   else
      if [ -f $filename ]
      then
         rm $filename
      fi 
   fi 

return $?

}

############################################################
####  MISC SQL FUNCTIONS
############################################################

###------------------------------------------------
function run_db_shutdown
{

   output_var db_shutdown_$ORACLE_SID.out

   echo "Shutting down DB $ORACLE_SID At `date` ..."

   sqlplus /nolog <<EOFSQL: >> /dev/null 2>> $OUTPUT
connect / as sysdba
shutdown immediate;
exit;
EOFSQL:

   if [ $? != 0 ]
   then
      echo "Error in shutdown DB  $ORACLE_SID At `date`" >> $OUTPUT
      ERRFLAG=1
      return
   fi 

   echo "DB $ORACLE_SID Shutdown At `date`"

   return $?
}

###------------------------------------------------
function run_db_startup
{
   output_var db_startup_$ORACLE_SID.out

   echo "Starting DB $ORACLE_SID At `date` ..."

   sqlplus /nolog <<EOFSQL: >> /dev/null 2>> $OUTPUT
connect / as sysdba
startup;
exit;
EOFSQL:

   if [ $? != 0 ]
   then
      echo "Error in starting DB  $ORACLE_SID At `date`" >> $$OUTPUT
      ERRFLAG=1
      return
   fi 

   echo "DB $ORACLE_SID Started At `date`"

   return $?
}


############################################################
####  REPORTING FUNCTIONS
############################################################

###-------------------------------------------------------------------------------------
function rpt_invalid_objects
{
   USAGE="Usage: rpt_invalid_objects arg1  (arg1=mailing list)"

   if test "$#" -lt 1
   then
     echo $USAGE
     return 1
   fi

   mailist=$1 

   output_var invalid_objects_$mailist.out


   sqlplus -s / <<EOF > /dev/null
   whenever sqlerror exit failure
   set heading on feedback off  pagesize 9999 linesize 130

   spool $OUTPUT

select substr(owner,1,15)OWNER, substr(object_name,1,40) OBJECT, object_type, status
from dba_objects
where status not in ('VALID')
order by owner, object_name
/

select
owner,object_type,status,count(*)
from dba_objects
where status not in ('VALID')
group by owner,object_type,status
/

   spool off

   exit
EOF

   mailit_or_not "Invalid Objects $ORACLE_SID" $mailist


return $?
}

###-------------------------------------------------------------------------------------
function rpt_process_IO
{
   USAGE="Usage: rpt_process_IO arg1  (arg1=mailing list)"

   if test "$#" -lt 1
   then
     echo $USAGE
     return 1
   fi

   mailist=$1 

   output_var process_io_$mailist.out

   sqlplus -s / <<EOF > /dev/null
   whenever sqlerror exit failure
   set heading on feedback off  pagesize 9999

   spool $OUTPUT

set heading on pagesize 1000 linesize 155

select Username,  osuser, Consistent_Gets, Block_Gets, Physical_Reads, 100*(Consistent_Gets+Block_Gets-Physical_Reads)/ (Consistent_Gets+Block_Gets) HitRatio 
from V\$SESSION, V\$SESS_IO 
where V\$SESSION.SID = V\$SESS_IO.SID 
and (Consistent_Gets+Block_Gets)>0
and Username is not null
/

   spool off

   exit
EOF

   mailit_or_not "Process I/O $ORACLE_SID" $mailist

return $?
}

###-------------------------------------------------------------------------------------
function rpt_parse_calls
{
   USAGE="Usage: rpt_parse_calls arg1  (arg1=mailing list)"

   if test "$#" -lt 1
   then
     echo $USAGE
     return 1
   fi

   mailist=$1 

   output_var parse_calls_$mailist.out

   sqlplus -s / <<EOF > /dev/null
   whenever sqlerror exit failure
   set heading on feedback off  pagesize 9999

   spool $OUTPUT

select substr (sql_text,1,80) SQL,
       parse_calls,
       executions
from   v\$sqlarea
where  parse_calls > 100
and    executions < 2*parse_calls
/

select sid, value
from v\$sesstat
where statistic# = 131  --- (parse count)
and value > 100
order by 2 desc
/

   spool off

   exit
EOF

   mailit_or_not "Parse Calls $ORACLE_SID" $mailist

return $?
}


###-------------------------------------------------------------------------------------
function rpt_sort_usage
{
   USAGE="Usage: rpt_sort_usage arg1  (arg1=mailing list)"

   if test "$#" -lt 1
   then
     echo $USAGE
     return 1
   fi

   mailist=$1 

   output_var sort_usage_$mailist.out

   sqlplus -s / <<EOF > /dev/null
   whenever sqlerror exit failure
   set heading on feedback off  pagesize 9999

   spool $OUTPUT

SELECT  substr(vs.username,1,20) "db user",
        substr(vs.osuser,1,20)   "os user",
        substr(vsn.name,1,20)   "Type of Sort", 
        vss.value
FROM    v\$session vs, v\$sesstat vss, v\$statname vsn
WHERE   (vss.statistic#=vsn.statistic#) 
AND        (vs.sid = vss.sid) 
AND        (vsn.name like '%sort%')ORDER BY 2,3
/

SELECT se.program,se.username, se.sid, se.serial#, su.contents     
FROM v\$session se, v\$sort_usage su
WHERE se.saddr = su.session_addr
/

   spool off

   exit
EOF

   mailit_or_not "Sort Area Usage $ORACLE_SID" $mailist

return $?
}

###-------------------------------------------------------------------------------------
function rpt_active_rollbacks
{
   USAGE="Usage: rpt_active_rollbacks arg1  (arg1=mailing list)"

   if test "$#" -lt 1
   then
     echo $USAGE
     return 1
   fi

   mailist=$1 

   output_var active_rollbacks_$mailist.out

   sqlplus -s / <<EOF > /dev/null
   whenever sqlerror exit failure
   set heading on feedback off  pagesize 9999

   spool $OUTPUT

select s.osuser OSUSER,
       s.username USERNAME,
       s.sid SID,
       segment_name SEG_NAME,
       sa.sql_text SQLTEXT
from   v\$session s,
       v\$transaction t,
       dba_rollback_segs r,
       v\$sqlarea sa
where  s.taddr = t.addr
and    t.xidusn = r.segment_id(+)
and    s.sql_address = sa.address(+)
/

   spool off

   exit
EOF

   mailit_or_not "Active Rollbacks $ORACLE_SID" $mailist

return $?
}

###-------------------------------------------------------------------------------------
function rpt_latches
{
   USAGE="Usage: rpt_latches arg1  (arg1=mailing list)"

   if test "$#" -lt 1
   then
     echo $USAGE
     return 1
   fi

   mailist=$1 

   output_var latches_$mailist.out

   sqlplus -s / <<EOF > /dev/null
   whenever sqlerror exit failure
   set heading on feedback off  pagesize 9999

   spool $OUTPUT

select sid, p2 "LATCH#", p3 "SLEEPS"
from v\$session_wait
where event = 'latch free'
order by 2,3
/
select w.sid, rpad(l.name,25, ' ') "latch", w.p3 "sleeps"
from v\$latchname l, v\$session_wait w
where w.event = 'latch free'
and l.latch# = w.p2
order by 2,3
/
select rpad(s.osuser,15, ' '),   h.sid,  rpad(h.name,25, ' ')
from v\$latchholder h, v\$session s
where h.sid = s.sid
/
select rpad(a.name,25, ' ') name
,a.gets gets
,to_char(a.misses*100/decode(a.gets,0,1,a.gets),'990.9') miss
,to_char(a.spin_gets*100/decode(a.misses,0,1,a.misses),'990.9') cspins
,to_char(a.sleep1*100/decode(a.misses,0,1,a.misses),'990.9') csleep1
,to_char(a.sleep2*100/decode(a.misses,0,1,a.misses),'990.9') csleep2
,to_char(a.sleep3*100/decode(a.misses,0,1,a.misses),'990.9') csleep3
,to_char(a.sleep4*100/decode(a.misses,0,1,a.misses),'990.9') csleep4
,to_char(a.sleep5*100/decode(a.misses,0,1,a.misses),'990.9') csleep5
,to_char(a.sleep6*100/decode(a.misses,0,1,a.misses),'990.9') csleep6
,to_char(a.sleep7*100/decode(a.misses,0,1,a.misses),'990.9') csleep7
,to_char(a.sleep8*100/decode(a.misses,0,1,a.misses),'990.9') csleep8
,to_char(a.sleep9*100/decode(a.misses,0,1,a.misses),'990.9') csleep9
,to_char(a.sleep10*100/decode(a.misses,0,1,a.misses),'990.9') csleep10
,to_char(a.sleep11*100/decode(a.misses,0,1,a.misses),'990.9') csleep11
from v\$latch a
where a.misses <> 0
order by 2
/ 

   spool off

   exit
EOF

   mailit_or_not "Latch Information $ORACLE_SID" $mailist

return $?
}

###-------------------------------------------------------------------------------------
function rpt_system_memory
{
   USAGE="Usage: rpt_system_memory arg1  (arg1=mailing list)"

   if test "$#" -lt 1
   then
     echo $USAGE
     return 1
   fi

   mailist=$1 

   output_var system_memory_$mailist.out

   sqlplus -s / <<EOF > /dev/null
   whenever sqlerror exit failure
   set heading off feedback off  pagesize 9999

   spool $OUTPUT

select round((sum(decode(name, 'free memory', bytes, 0))  / sum(bytes)) * 100,2) || '% SGA PERCENT FREE'
from v\$sgastat
/
select sum(sharable_mem) || ' SQLArea Total'
from v\$sqlarea
/
select sum(sharable_mem) || ' Dynamic SQL SQLArea'
from v\$sqlarea
where executions > 5
/
select sum(sharable_mem) || ' SQLArea > 1000 bytes and 100 excutions'
from v\$sqlarea
where sharable_mem > 1000
and executions > 100
/
select sum(250 * users_opening) || ' SQLArea Cursors'
from v\$sqlarea
/
select sum(sharable_mem) || ' DBObject Total'
from v\$db_object_cache
/
select round(sum(reloads) / sum(pins) * 100,2) || ' LIBRARY CACHE RELOADS (percent)'
from v\$librarycache
where namespace in ('SQL AREA','TABLE/PROCEDURE','BODY','TRIGGER')
/
select sum(reloads) || ' LIBRARY CACHE RELOADS (number of reloads)'
from v\$librarycache
where namespace in ('SQL AREA','TABLE/PROCEDURE', 'BODY','TRIGGER')
/

select file#, block#, count(*) || ' SQL CLONES IN SGA'
from v\$bh
group by file#, block#
having count(*) > 2
/

   spool off

   exit
EOF

   mailit_or_not "System Memory $ORACLE_SID" $mailist

return $?
}

###-------------------------------------------------------------------------------------
function rpt_database_layout
{
   USAGE="Usage: rpt_database_layout arg1  (arg1=mailing list)"

   if test "$#" -lt 1
   then
     echo $USAGE
     return 1
   fi

   mailist=$1 

   output_var database_layout_$mailist.out

   sqlplus -s / <<EOF > /dev/null
   whenever sqlerror exit failure
   set heading on feedback off  pagesize 9999

   spool $OUTPUT

prompt
prompt ======================================
prompt   Tablespace/Datafile Listing
prompt =====================================
prompt
prompt
column  "Location"              format A30;
column  "Tablespace Name"       format A15;
column  "Size(M)"               format 999,990;

break on "Tablespace Name" skip 1 nodup;
compute sum of "Size(M)" on "Tablespace Name";

SELECT  tablespace_name "Tablespace Name",
        file_name "Location",
        bytes/1048576 "Size(M)"
FROM sys.dba_data_files
order by tablespace_name
/

prompt
prompt ======================================
prompt   Redo Log Listing
prompt =====================================
prompt
prompt
column  "Group"         format 999;
column  "File Location" format A40;
column  "Bytes (K)"     format 999,990;

break on "Group" skip 1 nodup;


select  a.group# "Group",
        b.member "File Location",
        a.bytes/1024 "Bytes (K)"
from    v\$log a,
        v\$logfile b
where a.group# = b.group#
order by 1,2
/

prompt
prompt ======================================
prompt   Rollback Listing
prompt =====================================
prompt
prompt
column  "Segment Name"  format A15;
column  "Tablespace"    format A15;
Column  "Initial (K)"   Format 999,990;
Column  "Next (K)"      Format 999,990;
column  "Min Ext."      FORMAT 9990;
column  "Max Ext."      FORMAT 9990;
column  "Status"        Format A7;

select  segment_name "Segment Name",
        tablespace_name "Tablespace",
        initial_extent/1024 "Initial (K)",
        next_extent/1024 "Next (K)",
        min_extents "Min Ext.",
        max_extents "Max Ext.",
        status "Status"
from    sys.dba_rollback_segs
order by tablespace_name,
        segment_name 
/

   spool off

   exit
EOF

   mailit_or_not "Database Layout $ORACLE_SID" $mailist

return $?
}

###-------------------------------------------------------------------------------------
function rpt_freespace
{
   USAGE="Usage: rpt_freespace arg1  (arg1=mailing list)"

   if test "$#" -lt 1
   then
     echo $USAGE
     return 1
   fi

   mailist=$1 

   output_var freespace_$mailist.out

   sqlplus -s / <<EOF > /dev/null
   whenever sqlerror exit failure
   set heading on feedback off linesize 132 pagesize 9999
     

   spool $OUTPUT

col free heading 'Free(Mb)' format 999999.9
col total heading 'Total(Mb)' format 9999999.9
col used heading 'Used(Mb)' format 999999.9
col pct_free heading 'Pct|Free' format 99999.9
col largest heading 'Largest(Mb)' format 99999.9
compute sum of total on report
compute sum of free on report
compute sum of used on report

break on report

select substr(a.tablespace_name,1,25) tablespace,
round(sum(a.total1)/1024/1024, 1) Total,
round(sum(a.total1)/1024/1024, 1)-round(sum(a.sum1)/1024/1024, 1) used,
round(sum(a.sum1)/1024/1024, 1) free,
round(sum(a.sum1)/1024/1024, 1)*100/round(sum(a.total1)/1024/1024, 1) pct_free,
round(sum(a.maxb)/1024/1024, 1) largest,
max(a.cnt) fragment
from
(select tablespace_name, 0 total1, sum(bytes) sum1,
max(bytes) MAXB,
count(bytes) cnt
from dba_free_space
group by tablespace_name
union
select tablespace_name, sum(bytes) total1, 0, 0, 0 from dba_data_files
group by tablespace_name) a
group by a.tablespace_name
/

   spool off

   exit
EOF

   mailit_or_not "Tablespace Freespace $ORACLE_SID" $mailist

return $?
}

###-------------------------------------------------------------------------------------
function rpt_tablespace_mapping
{
   USAGE="Usage: rpt_tablespace_mapping arg1  (arg1=mailing list)"

   if test "$#" -lt 1
   then
     echo $USAGE
     return 1
   fi

   mailist=$1 

   echo "Enter Tablespace to Map: \c"
   read tablespace

   output_var tablespace_mapping_$mailist.out

   sqlplus -s / <<EOF > /dev/null
   whenever sqlerror exit failure
   set heading on feedback off  pagesize 9999

   spool $OUTPUT

rem
rem  File:
rem  Location:
rem  Parameters: the tablespace name being mapped
rem
rem  Sample invocation:
rem @List_Tablespace_Space_Mapping AEGLD
rem
rem  This scripts generates mapping of space usage
rem  (free space vs used in a tablespace.  It graphically
rem  shows segment and free space fragmentation.
rem

set pagesize 1000 linesize 132 verify off
column file_id heading "File|Id"

SELECT
     'free space' owner,        /*"owner" of free space*/
     '   ' object,              /*blank object name*/
     file_id,                   /*file ID for extent header*/
     block_id,                  /*block ID for the extent header*/
     blocks                     /*length of the extent in blocks*/
FROM
     dba_free_space
WHERE
     tablespace_name = upper('$tablespace')
UNION
SELECT
     substr(owner,1,20),        /*owner name (first 20 chars)*/
     substr(segment_name,1,20), /*segment name*/
     file_id,                   /*file ID for extent header*/
     block_id,                  /*block ID for block header*/
     blocks                     /*length of extent in blocks*/
FROM dba_extents
WHERE
     tablespace_name = upper('$tablespace')
ORDER BY 3,4
/

   spool off

   exit
EOF

   mailit_or_not "Tablespace Mapping $ORACLE_SID" $mailist

return $?
}

###-------------------------------------------------------------------------------------
function rpt_extents_over_threshold
{
   USAGE="Usage: rpt_extents_over_threshold arg1  (arg1=mailing list)"

   if test "$#" -lt 1
   then
     echo $USAGE
     return 1
   fi

   mailist=$1 

   output_var extents_over_threshold_$mailist.out

   sqlplus -s / <<EOF > /dev/null
   whenever sqlerror exit failure
   set heading on  feedback off  pagesize 9999 linesize 132

   spool $OUTPUT

ttitle center 'SEGMENTS THAT HAVE OVER 100 EXTENTS' skip1

select
  substr(owner,1,10)                    owner,
  substr(segment_name,1,30)             segname,
  substr(segment_type,1,8)              segtype,
  extents                               excount,
  max_extents                           maxexts,
  max_extents-extents                   extdiff
from
  dba_segments
where
  (extents > 100)
and (segment_type NOT IN ('CACHE','ROLLBACK'))
and owner NOT IN ('SYS','SYSTEM')
order by owner
/

   spool off

   exit
EOF

   mailit_or_not "Segments Over Extent Threshold $ORACLE_SID" $mailist

return $?
}


###-------------------------------------------------------------------------------------
function rpt_tuning_statistics
{
   USAGE="Usage: rpt_tuning_statistics arg1  (arg1=mailing list)"

   if test "$#" -lt 1
   then
     echo $USAGE
     return 1
   fi

   mailist=$1

   output_var tuning_statistics_$mailist.out

   sqlplus -s / <<EOF > /dev/null
   whenever sqlerror exit failure


rem ***************************************************************************

rem Script:    tunechek.sql
rem Purpose:   Provide tuning statistics for an Oracle 7 database instance
rem Author:    Joe Greene
rem Revised:   6/29/94
rem Inputs:    Much of the logic in this script is taken from scripts found
rem            on the Compuserve Oracle Forum, the Oracle Server 
rem            Administrator's Guide and other references

rem ***************************************************************************

rem Set up environment

set termout off
set pause off
set pages 540
set feedback off
set time off

rem ***************************************************************************

rem send output to a file

   spool $OUTPUT 
 
rem ***************************************************************************

rem Print overall heading for report

set heading off

prompt ########################################################################
prompt #               Oracle Database Tuning Report                          #
prompt ########################################################################
prompt
prompt Instance Name:

select value from v\$parameter where name='db_name'
/

prompt
prompt
prompt Date Of This Report:

Column today format a30

select to_char(sysdate,'dd Month YYYY  HH24:MI') today from sys.dual
/

prompt
prompt

set heading on

rem ***************************************************************************

rem  Section of Memory Allocation checks

prompt ########################################################################
prompt
prompt Memory Allocation Checks
prompt
prompt ########################################################################
Prompt
prompt

rem ***************************************************************************

rem Library Cache checks

column libcache format 99.99 heading 'Library Cache Miss Ratio (%)'

prompt Library Cache Check 
prompt
prompt Goal:			<1%
prompt
prompt Corrective Action:	Increase shared_pool_size
prompt .			Write identical SQL statements
prompt

select sum(reloads)/sum(pins) *100 libcache
from v\$librarycache
/

prompt
prompt

rem ***************************************************************************

rem Data dictionary cache checks


column ddcache format 99.99 heading 'Data Dictionary Cache Miss Ratio (%)'

prompt ########################################################################
prompt
prompt Data Dictionary Cache Check
prompt
prompt Goal:			<10%
prompt
prompt Corrective Actions:	Increase shared_pool_size
prompt

select sum(getmisses)/sum(gets) * 100 ddcache
from v\$rowcache
/

prompt
prompt

rem ***************************************************************************

rem Shared Pool Checks

column sess_mem heading "Session Memory (Bytes)" format 999,999,999
column sh_pool heading "Shared_Pool_Size (Bytes)" format 999,999,999
column name noprint

prompt ########################################################################
prompt
prompt Multi-Threaded Server Session Memory
prompt
prompt Goal:			Shared_pool_size at lease equal to maximum 
prompt .			session memory
prompt
prompt Corrective Action:	Increase shared_pool_size
prompt

select sum(value) sess_mem
	from v\$sysstat
	where name='session memory'
/
prompt
select name,to_number(value) sh_pool
	from v\$parameter
	where name='shared_pool_size'
/

prompt
prompt

rem ***************************************************************************

rem Buffer Cache Checks

column pct heading "Hit Ratio (%)" format 999.9

prompt ########################################################################
prompt
prompt Buffer Cache Hit Ratio
prompt
prompt Goal:			Above 60 to 70 percent
prompt
prompt Corrective Action:	Increase db_block_buffers
prompt

select (1- (sum(decode(a.name,'physical reads',value,0)))/
	(sum(decode(a.name,'db block gets',value,0)) +
	sum(decode(a.name,'consistent gets',value,0)))) * 100 pct
	from v\$sysstat a
/

prompt
prompt

rem ***************************************************************************

rem I/O checks

prompt ########################################################################
prompt
prompt Disk I/O Checks
prompt
prompt ########################################################################

rem ***************************************************************************

rem Disk Activity Check

column name print
column name heading "Data File" format a45
column phyrds heading "Reads" format 999,999,999
column phywrts heading "Writes" format 999,999,999

prompt ########################################################################
prompt
prompt Disk Activity Check
prompt
prompt Goal:			Balance Load Between Disks
prompt
prompt Corrective Action:	Transfer files, reduce other loads to disks,
prompt .			striping disks, separating data files and redo
prompt .			logs
prompt
prompt

select name,phyrds,phywrts
from v\$datafile dr,v\$filestat fs
where dr.file#=fs.file#
/

prompt
prompt

rem ***************************************************************************

rem Contention Checks

prompt ########################################################################
prompt
prompt Oracle Contention Checks
prompt
prompt ########################################################################

rem ***************************************************************************

rem Rollback Segment Contention

column class heading "Class" format a20
column count heading "Counts" format 999,999,999
column gets heading "Total Gets" format 999,999,999,999

prompt ########################################################################
prompt
prompt Rollback Segment Contention
prompt
prompt Goal:			Measured Counts < 1% of total gets
prompt .			(the choice of Oracle column names makes it
prompt .			impossible to do this calculation for you)
prompt
prompt Corrective Action:	Add more rollback segments
prompt
prompt

select sum(value) gets
	from v\$sysstat
	where name in ('db block gets','consistent gets')
/
prompt
prompt
select class,count
	from v\$waitstat
	where class in ('system undo header','system undo block',
	  'undo header','undo block')

/

prompt
prompt

rem ***************************************************************************

rem Latch Contention

column name heading "Latch Type" format a25
column pct_miss heading "Misses/Gets (%)" format 999.99999
column pct_immed heading "Immediate Misses/Gets (%)" format 999.99999

prompt ########################################################################
prompt
prompt Latch Contention Analysis
prompt
prompt Goal:			< 1% miss/get for redo allocation
prompt .			< 1% immediate miss/get for redo copy
prompt
prompt Corrective Action:	Redo allocation-  decrease log_small_entry_
prompt .			  max_size
prompt .			Redo copyIncrease log_simultaneous_copies
prompt
prompt

select n.name,misses*100/(gets+1) pct_miss,
	immediate_misses*100/(immediate_gets+1) pct_immed
	from v\$latchname n,v\$latch l
	where n.latch# = l.latch# and
	n.name in ('redo allocation','redo copy')
/

prompt
prompt

rem ***************************************************************************

rem MTS Dispatcher contention

column protocol heading "Protocol" format a15
column pct heading "Percent Busy" format 999.99999

prompt ########################################################################
prompt
prompt MTS Dispatcher Contention
prompt
prompt Goal:			< 50%
prompt
prompt Corrective Action:	Add dispatcher processes
prompt
prompt

select network protocol,sum(busy)*100/(sum(busy)+sum(idle)) pct
	from v\$dispatcher
	group by network
/

prompt
prompt

rem ***************************************************************************

rem Shared Server Processes Contention

column wait heading "Average Wait Per Request (1/100 sec)" format 9,999.99
column sh_proc heading "Shared Server Processes" format 99
column max_srv heading "MTS_MAX_SERVERS" format 99

prompt ########################################################################
prompt
prompt Shared Server Process Contention
prompt
prompt Goal:			Shared processes less that MTS_MAX_SERVERS
prompt
prompt Corrective Action:	Alter MTS_MAX_SERVERS
prompt
prompt

select decode(totalq,0,'No Requests',wait/totalq || '1/100 sec')
"Average wait per request"
from v\$queue
where type='COMMON'
/

prompt

select count(*) "Shared Server Processes"
from v\$shared_server
where status !='QUIT'
/

prompt

select name,to_number(value) "MTS_MAX_SERVERS"
        from v\$parameter
        where name='mts_max_servers'
/

prompt
prompt

rem ***************************************************************************

rem Redo Log Buffer Space Contention

column value heading "Requests" format 999,999,999
column name noprint

prompt ########################################################################
prompt
prompt Redo Log Buffer Space Contention
prompt
prompt Goal:			Near 0
prompt
prompt Corrective Action:	Increase size of redo log buffer
prompt
prompt

select name,value
	from v\$sysstat
	where name='redo log space requests'
/

column name print

prompt
prompt

rem ***************************************************************************

rem Sort Memory Contention

column value heading "Number" format 999,999,999
column name heading "Type" format a15

prompt ########################################################################
prompt
prompt Sort Memory Contention
prompt
prompt Goal:			Mimimize sorts to disk
prompt
prompt Corrective Action:	Increase sort-area-size
prompt
prompt

select name,value
	from v\$sysstat
	where name in ('sorts (memory)','sorts (disk)')
/

prompt
prompt

rem ***************************************************************************

rem Free List Contention

column class heading "Class" format a20
column count heading "Counts" format 999,999,999
column gets heading "Total Gets" format 999,999,999,999

prompt ########################################################################
prompt
prompt Free List Contention
prompt
prompt Goal:			Number of counts less that 1% of total gets
prompt
prompt Corrective Action:	Increase free lists (per table)
prompt
prompt

select sum(value) gets
	from v\$sysstat
	where name in ('db block gets','consistent gets')
/
prompt

select class,count
	from v\$waitstat
	where class='free list'
/

prompt
prompt

rem ***************************************************************************

rem Insert commentary for sar checks that will be appended on the end

prompt
prompt ########################################################################
prompt ########################################################################
prompt
prompt sar statistics
prompt
prompt These statistics have been gathered by the operating system's sar
prompt utility.
prompt
prompt The data will be concantonated onto the end of this file approximately
prompt five minutes after the dbcheck script is started (these processes
prompt monitor operating system activity for 5 minutes)
prompt
prompt
prompt Factors to watch:
prompt
prompt %idle > 0 at peak load	If users see appreciable degradation and
prompt .			user CPU time > system CPU time and memory
prompt .			and disks are not issued, then larger
prompt .			CPU needed
prompt
prompt bread,bwrit,pread,pwrit	If this sum if over 40 for two drives or 
prompt .			60 for 4 to 8 drives, I/O problem
prompt
prompt %wio			If consistently greater than 20, may be
prompt .			I/O bound
prompt
prompt %rcache > 90		For file systems, else I/O bound
prompt % wcache > 60		For file systems, else I/O bound
prompt
prompt page outs,swaps outs	If high, memory may be too small
prompt
prompt
prompt ########################################################################
prompt
prompt System Monitoring Data
prompt
prompt ########################################################################
prompt
prompt

rem ***************************************************************************

rem Close out SQL*Plus script

spool off

rem ***************************************************************************
rem ***************************************************************************

   exit
EOF

   mailit_or_not "Tuning Statistics $ORACLE_SID" $mailist

return $?
} 


###-------------------------------------------------------------------------------------
function rpt_performance_check
{
   USAGE="Usage: rpt_performance_check arg1  (arg1=mailing list)"

   if test "$#" -lt 1
   then
     echo $USAGE
     return 1
   fi

   mailist=$1

   output_var performance_check_$mailist.out

   sqlplus -s / <<EOF > /dev/null
   whenever sqlerror exit failure
   set heading on feedback off  pagesize 9999

   spool $OUTPUT


rem
rem Procedure           perform.sql
rem
rem Description         This PL/SQL script monitors a database.
rem                     The following are monitored :-
rem
rem                     Buffer Cache
rem                     Library Cache





rem                     Dictionary Cache
rem                     Rollback Segment Waits
rem                     Sorts to disk
rem                     Cursor Usage
rem                     Transactions
rem                     File I/O Rate
rem                     Number of Locks
rem                     Unarchived Logs
rem                     Redo Log Space Waits
rem                     Enqueue Waits
rem
rem
rem Argument(s)         Number of loops and interval between in seconds
rem                     (Suggested interval 900).
rem
rem Author              Duncan Berriman, 25/5/98
rem                     Duncan@dcl.co.uk
rem                     http://www.dcl.co.uk

set echo on;
set serveroutput on size 10000;

declare

  /* Fetched from database */

  v_fetch_db_block_gets number :=0;
  v_fetch_physical_reads number :=0;
  v_fetch_rollback_gets number :=0;
  v_fetch_rollback_waits number :=0;
  v_fetch_sorts_disk number :=0;
  v_fetch_sorts_memory number :=0;
  v_fetch_redo_space_requests number :=0;
  v_fetch_enqueue_waits number :=0;
  v_fetch_library_pins number :=0;
  v_fetch_library_pinhits number :=0;
  v_fetch_dictionary_gets number :=0;
  v_fetch_dictionary_misses number :=0;
  v_fetch_total_io number :=0;

  /* parameters from INIT.ORA */
  v_open_cursors_parameter number;
  v_transactions_parameter number;

  /* Calculated values */
  v_logical_reads number;
  v_consistent_gets number;
  v_db_block_gets number;
  v_physical_reads number;
  v_rollback_gets number;
  v_rollback_waits number;
  v_sorts_disk number;
  v_sorts_memory number;
  v_redo_space_requests number;
  v_enqueue_waits number;
  v_library_pins number;
  v_library_pinhits number;
  v_dictionary_gets number;
  v_dictionary_misses number;
  v_total_io number;

  /* Fetched from database */
  v_open_cursors_current number;
  v_transactions number;
  v_unarchived_count number;
  v_total_locks number;

  /* Store last values for calculations */
  v_last_consistent_gets number;
  v_last_db_block_gets number;

  v_last_physical_reads number;
  v_last_rollback_gets number;
  v_last_rollback_waits number;
  v_last_sorts_disk number;
  v_last_sorts_memory number;
  v_last_redo_space_requests number;
  v_last_enqueue_waits number;
  v_last_library_pins number;
  v_last_library_pinhits number;
  v_last_dictionary_gets number;
  v_last_dictionary_misses number;
  v_last_total_io number;

/* Ratio */
  v_buffer_cache_hit_ratio integer;
  v_rollback_wait_ratio integer;
  v_sorts_disk_ratio integer;
  v_open_cursors_ratio integer;
  v_library_pinhits_ratio integer;
  v_dictionary_cache_ratio integer;
  v_transactions_ratio integer;
  v_total_io_rate integer;

  /* General */
  v_counter integer;
  v_interval integer;
  v_date_time varchar2(15);

  procedure db_output (message in varchar) is

  begin
    dbms_output.put_line(message);
  end;



  procedure get_param is

  begin
    select value into v_open_cursors_parameter from v\$parameter where name = 'open_cursors';
    select value into v_transactions_parameter from v\$parameter where name = 'transactions';
  end;

  procedure get_stats is

  begin
    v_last_consistent_gets := v_fetch_consistent_gets;
    v_last_db_block_gets := v_fetch_db_block_gets;
    v_last_physical_reads := v_fetch_physical_reads;
    v_last_library_pins := v_fetch_library_pins;
    v_last_library_pinhits := v_fetch_library_pinhits;
    v_last_dictionary_gets := v_fetch_dictionary_gets;
    v_last_dictionary_misses := v_fetch_dictionary_misses;
    v_last_rollback_gets := v_fetch_rollback_gets;
    v_last_rollback_waits := v_fetch_rollback_waits;
    v_last_sorts_disk := v_fetch_sorts_disk;
    v_last_sorts_memory := v_fetch_sorts_memory;
    v_last_enqueue_waits := v_fetch_enqueue_waits;
    v_last_redo_space_requests := v_fetch_redo_space_requests;
    v_last_total_io := v_fetch_total_io;

    select value into v_fetch_consistent_gets from v\$sysstat where name = 'consistent gets';
    select value into v_fetch_db_block_gets from v\$sysstat where name = 'db block gets';
    select value into v_fetch_physical_reads from v\$sysstat where name = 'physical reads';
    select sum(pinhits),sum(pins) into v_fetch_library_pinhits,v_fetch_library_pins from v\$librarycache;
    select sum(gets),sum(getmisses) into v_fetch_dictionary_gets,v_fetch_dictionary_misses from v\$rowcache;
    select sum(waits),sum(gets) into v_fetch_rollback_waits,v_fetch_rollback_gets from v\$rollstat;
    select value into v_fetch_sorts_disk from v\$sysstat where name = 'sorts (disk)';
    select value into v_fetch_sorts_memory from v\$sysstat where name = 'sorts (memory)';
    select value into v_open_cursors_current from v\$sysstat where name = 'opened cursors current';
    select value into v_fetch_redo_space_requests from v\$sysstat where name = 'redo log space requests';
    select value into v_fetch_enqueue_waits from v\$sysstat where name = 'enqueue waits';
    select sum(xacts) into v_transactions from v\$rollstat;
    select sum(phyrds)+sum(phywrts) into v_fetch_total_io from v\$filestat;
    select count(lockwait) into v_total_locks from v\$session where lockwait is not null;
    select count(archived) into v_unarchived_count from v\$log where archived = 'NO' and status not in ('INACTIVE','CURRENT');
  end;

begin
  get_param;    /* Get Fixed parameters */
  get_stats;    /* Get Initial Values of statistics */

  v_counter := &loops;
  v_interval := &interval;

  while v_counter > 0
  loop
    /* Sleep for more */
    v_date_time := to_char(sysdate,'dd-mon-yy hh24:mi');
    db_output('Sleeping at '||v_date_time||'...');
    v_counter := v_counter - 1;
    dbms_lock.sleep(v_interval);  

    /* Get statistics */
    get_stats;

    /* Check Buffer Cache Hit Ratio */
    v_consistent_gets := v_fetch_consistent_gets - v_last_consistent_gets;
    if v_consistent_gets < 0 
    then
      v_consistent_gets := v_fetch_consistent_gets;
    end if;
    
    v_db_block_gets := v_fetch_db_block_gets - v_last_db_block_gets;
    if v_db_block_gets < 0 
    then
      v_db_block_gets := v_fetch_db_block_gets;
    end if;

    v_physical_reads := v_fetch_physical_reads - v_last_physical_reads;
    if v_physical_reads < 0 
    then
      v_physical_reads := v_fetch_physical_reads;
    end if;

    v_logical_reads := v_consistent_gets + v_db_block_gets;
    if v_logical_reads < 1
    then
      v_logical_reads := 1;
    end if;

    v_buffer_cache_hit_ratio := (v_logical_reads*100)/(v_logical_reads + v_physical_reads);
    db_output('Buffer Cache Hit Ratio is '||to_char(v_buffer_cache_hit_ratio)||'
%');

    /* Check Library Cache */
    v_library_pinhits := v_fetch_library_pinhits - v_last_library_pinhits;
    if v_library_pinhits < 0
    then
      v_library_pinhits := v_fetch_library_pinhits;
    end if;

    v_library_pins := v_fetch_library_pins - v_last_library_pins;
    if v_library_pins < 0
    then
      v_library_pins := v_fetch_library_pins;
    end if;
 
    if v_library_pins < 1
    then
      v_library_pins := 1;
    end if;

    v_library_pinhits_ratio := ((v_library_pinhits * 100) / v_library_pins);
    db_output('Library Cache Hit Ratio is '||to_char(v_library_pinhits_ratio)||'%');

    /* Check Library Cache */
    v_dictionary_misses := v_fetch_dictionary_misses - v_last_dictionary_misses;
    if v_dictionary_misses < 0
    then
      v_dictionary_misses := v_fetch_dictionary_misses;
    end if;

    v_dictionary_gets := v_fetch_dictionary_gets - v_last_dictionary_gets;
    if v_dictionary_gets < 0
    then
      v_dictionary_gets := v_fetch_dictionary_gets;
    end if;

    if v_dictionary_gets < 1
    then
      v_dictionary_gets := 1;
    end if;

    v_dictionary_cache_ratio := ((v_dictionary_gets * 100) / (v_dictionary_misses + v_dictionary_gets));
    db_output('Dictionary Cache Hit Ratio is '||to_char(v_dictionary_cache_ratio)||'%');

    /* Check for Rollback segment waits */
    v_rollback_waits := v_fetch_rollback_waits - v_last_rollback_waits;
    if v_rollback_waits < 0 
    then
      v_rollback_waits := v_fetch_rollback_waits;
    end if;

    v_rollback_gets := v_fetch_rollback_gets - v_last_rollback_gets;
    if v_rollback_gets < 0 
    then
      v_rollback_gets := v_fetch_rollback_gets;
    end if;

    if v_rollback_gets < 1 
    then
      v_rollback_gets := 1;
    end if;

    v_rollback_wait_ratio := (v_rollback_waits * 100) / (v_rollback_gets);
    db_output('Rollback Segment Wait Ratio is '||to_char(v_rollback_wait_ratio)||'%');

    /* Check sorts to disk */
    v_sorts_disk := v_fetch_sorts_disk - v_last_sorts_disk;
    if v_sorts_disk < 0 
    then
      v_sorts_disk := v_fetch_sorts_disk;
    end if;

    v_sorts_memory := v_fetch_sorts_memory - v_last_sorts_memory;
    if v_sorts_memory < 0 
    then
      v_sorts_memory := v_fetch_sorts_memory;
    end if;

    if v_sorts_memory < 1 
    then
      v_sorts_memory := 1;
    end if;

    v_sorts_disk_ratio := (v_sorts_disk * 100) / (v_sorts_disk + v_sorts_memory);
    db_output('Sorts to Disk Ratio is '||to_char(v_sorts_disk_ratio)||'%');

    /* Check cursor usage */
    v_open_cursors_ratio := (v_open_cursors_current * 100) / (v_open_cursors_parameter);
    db_output('Cursor Usage Ratio is '||to_char(v_open_cursors_ratio)||'%'); 

    /* Check transaction usage */
    v_transactions_ratio := (v_transactions * 100) / (v_transactions_parameter);
    db_output('Transaction Usage Ratio is '||to_char(v_transactions_ratio)||'%'); 

    /* Check File IO Rate */
    v_total_io := v_fetch_total_io - v_last_total_io;
    if v_total_io < 0
    then
      v_total_io :=0;
    end if;

    v_total_io_rate := v_total_io / v_interval;
    db_output('File I/O Rate is '||to_char(v_total_io_rate)||' per second'); 

    /* Check number of locks */
    db_output('Number of users awaiting lock is '||to_char(v_total_locks));

    /* Check number of unarchived logs */
    db_output('Number of unarchived logs is '||to_char(v_unarchived_count));

    /* Check for redo log space waits */
    v_redo_space_requests := v_fetch_redo_space_requests - v_last_redo_space_requests;
    if v_redo_space_requests < 0 
    then
      v_redo_space_requests := v_fetch_redo_space_requests;
    end if;

    db_output('Redo Log Space Requests is '||to_char(v_redo_space_requests)); 

    /* Check for enqueue waits */
    v_enqueue_waits := v_fetch_enqueue_waits - v_last_enqueue_waits;
    if v_enqueue_waits < 0 
    then
      v_enqueue_waits := v_fetch_enqueue_waits;
    end if;

    db_output('Enqueue Waits is '||to_char(v_enqueue_waits)); 

  end loop;
end;
/

   spool off

   exit
EOF

   mailit_or_not "Performance Check $ORACLE_SID" $mailist

return $?
}


###-------------------------------------------------------------------------------------
function rpt_configuration_info
{
   USAGE="Usage: rpt_configuration_info arg1  (arg1=mailing list)"

   if test "$#" -lt 1
   then
     echo $USAGE
     return 1
   fi

   mailist=$1

   output_var configuration_info_$mailist.out

   sqlplus -s / <<EOF > /dev/null
   whenever sqlerror exit failure


rem ***************************************************************************

rem Script:    configcheck.sql
rem Purpose:   Provide configuration data for an Oracle 7 database instance
rem Author:    Joe Greene
rem Revised:   6/29/94
rem Inputs:    Much of the logic in this script is taken from scripts found
rem            on the Compuserve Oracle Forum, the Oracle Server 
rem            Administrator's Guide and other references

rem ***************************************************************************

rem Set up environment

set termout off
set pause off
set pages 540
set feedback off
set time off

rem ***************************************************************************

rem send output to a file

   spool $OUTPUT 
 
rem ***************************************************************************

rem Print overall heading for report

set heading off

prompt ########################################################################
prompt #               Oracle Database Configuration Report                   #
prompt ########################################################################
prompt
prompt Instance Name:

select value from v\$parameter where name='db_name'
/

prompt
prompt
prompt Date Of This Report:

Column today format a30

select to_char(sysdate,'dd Month YYYY  HH24:MI') today from sys.dual;

set heading on

prompt
prompt

rem ***************************************************************************

rem  Print datafiles associated with this database

column tablespace_name heading "Tablespace" format a22
column file_id heading ID format 999
column bytes heading "Bytes" format 99,999,999,999
column file_name heading "File Name" format a35

prompt ########################################################################
prompt
prompt Data Files Associated With This Database
prompt
prompt

select file_id,file_name,tablespace_name,bytes
	from sys.dba_data_files
/

prompt
prompt

rem ***************************************************************************

rem  List Redo Log Files Report

column member format a45

prompt ########################################################################
prompt
prompt Redo Log Files
prompt
prompt

select * from v\$logfile
/

prompt
prompt

rem ***************************************************************************

rem Tablespace Information Report

column init/next format a20
column min/max format a10
column pct format 999
column tablespace_name format a24 heading "Tablespace"

prompt ########################################################################
prompt
prompt Tablespace Information
prompt

select tablespace_name,initial_extent||'/'||next_extent "Init/Next",
	min_extents||'/'||max_extents "Min/Max",pct_increase pct,status
	from sys.dba_tablespaces
	where status != 'INVALID'
/

prompt
prompt

rem ***************************************************************************

rem  Non-data objects Listing

column owner noprint new_value owner_var
column segment_name format a30 heading "Object name"
column segment_type format a9 heading "Obj Type"
column sum(bytes) format 99,999,999,999 heading "Bytes Used"
column count(*) format 999 heading "#"

prompt ########################################################################
prompt
prompt Non-Data Objects Listing
prompt

select  owner , segment_name , segment_type ,
	sum(bytes) , sum(blocks) , count(*)
	from sys.dba_extents
	where segment_type not in ('TABLE','INDEX','CLUSTER')
	group by owner , segment_name , segment_type
	order by owner , segment_name , segment_type
/

prompt
prompt

rem ***************************************************************************

rem Database objects by type report

column etype format a20 heading 'Object Type'
column kount format 99,999 heading 'Count'
compute sum of kount on report
break on report

prompt ########################################################################
prompt
prompt Numbers of Database Objects by Type
prompt

select decode (o.type#,1,'INDEX' , 2,'TABLE' , 3 , 'CLUSTER' ,
	4, 'VIEW' , 5 , 'SYNONYM' , 6 , 'SEQUENCE' , '??' ) etype ,
	count(*) "Row kount"
	from sys.obj\$ o 
	where o.type# > 1
        group by o.type#
---	group by   decode (o.type#,1,'INDEX' , 2,'TABLE' , 3 , 'CLUSTER' , 4, 'VIEW' , 5 , 'SYNONYM' , 6 , 'SEQUENCE' , '??' )
union
select 'COLUMN' , count(*) kount
	from sys.col\$
union
select 'DB LINKS' , count(*) kount
	from sys.link\$
union
select 'CONSTRAINT' , count(*) kount
	from sys.con\$
/

prompt
prompt

rem ***************************************************************************

rem Background Processes

column name format a6 heading 'BGProc'
column description format a27
column error format 999999999999

prompt ########################################################################
prompt
prompt Oracle Background Processes Running
prompt

select paddr , name , description , error
from v\$bgprocess
where paddr != '00'
/

prompt
prompt

rem ***************************************************************************

rem SGA Sizing

column value format 999,999,999 heading 'Value - Bytes'
column name format a30 heading 'SGA Group Name'
compute sum of value on report
break on report

prompt ########################################################################
prompt
prompt SGA Sizing
prompt

select * from v\$sga
/

prompt
prompt

clear computes

rem ***************************************************************************

rem SGA Parameters

column num format 999 heading 'Num'
column value format a37 heading 'Parameter Value'
column name format a35 heading 'Parameter Name'

prompt ########################################################################
prompt
prompt SGA Parameter Listing
prompt

select num , name , value
	from v\$parameter
/

prompt

rem ***************************************************************************

rem Close out SQL*Plus script

spool off
exit

rem ***************************************************************************
rem ***************************************************************************

EOF

   mailit_or_not "Configuration Info $ORACLE_SID" $mailist

return $?
} 

###-------------------------------------------------------------------------------------
function rpt_rollback_info
{
   USAGE="Usage: rpt_rollback_info arg1  (arg1=mailing list)"

   if test "$#" -lt 1
   then
     echo $USAGE
     return 1
   fi

   mailist=$1

   output_var rollback_info_$mailist.out

   sqlplus -s / <<EOF > /dev/null
   whenever sqlerror exit failure

column nl newline;
set feedback off echo off  verify off pagesize 9999  linesize 100

   spool $OUTPUT 

ttitle off
select 'Rollback Segments are not using dedicated tablespaces. This often hinders performance.'
  from dual
where 0 <
(select count(*) from dba_tablespaces
  where tablespace_name in
   (select tablespace_name from dba_segments
     where segment_type like 'RO%'
       and tablespace_name != 'SYSTEM'
    INTERSECT
    select tablespace_name from dba_segments
     where segment_type not like 'RO%'))
/

select  segment_name, tablespace_name
  from  dba_rollback_segs
where   0 <
(select count(*) from dba_tablespaces
  where tablespace_name in
   (select tablespace_name from dba_segments
     where segment_type like 'RO%'
       and tablespace_name != 'SYSTEM'
    INTERSECT
    select tablespace_name from dba_segments
     where segment_type not like 'RO%'))
/

set heading off
select 'You have had a number of rollback segment waits. Try adding '|| sum(decode(waits,0,0,1)) nl,
       'rollback segments to avoid rollback header contention. '
 from v\$rollstat
/

ttitle 'Rollback Segment Activity Since the Instance Started'
set heading on

select usn "Rollback Table", Gets, Waits , xacts "Active Transactions"
  from v\$rollstat
/
ttitle 'Total Number of Rollback Waits Since the Instance Started'
select class, count
 from v\$waitstat
where class like '%undo%'
/ 

ttitle 'Misc. Rollback Segment Information'
select substr(n.name,1,10) rollback_seg, s.rssize, s.optsize, s.hwmsize, s.shrinks, s.wraps, s.extends
from v\$rollstat s, v\$rollname n
where n.usn = s.usn
/

select substr(se.username,1,10) username, tr.ubablk
from v\$session se, v\$transaction tr
where se.taddr = tr.addr
/

select substr(n.name,1,10) rollback_seg, s.writes, s.xacts, s.gets, s.waits
from v\$rollstat s, v\$rollname n
where n.usn = s.usn
/

select substr (r.name,1,10) rollback_seg,
       p.pid oracle_pid,
       p.spid system_pid,
       nvl(p.username, 'NO TRANSACTION') transaction,
       p.terminal
from v\$lock l, v\$process p, v\$rollname r
where l.addr = p.addr (+)
and trunc(l.id1 (+)/655536)=r.usn
and l.type (+) = 'TX'
and l.lmode (+) = 6
order by r.name
/ 

column usn format 990
column extents format 999 heading "EXT"
column shrinks format 9999999
column extends format 9999999
column xacts format 999 heading "ACT"
column waits format 9999
column wraps format 9999
column writes format 999,999,999,999
rem column aveshrink format 9999 heading "AVE|SHRNK"
column status format a10
column rssize format a6
column optsize format a6
column hwmsize format a6
column name format a6
break on report
compute sum of WRITES on report
compute sum of GETS on report
compute sum of WAITS on report
compute sum of AVEACTIVE on report
set pages 1000 lines 132
select NAME, XACTS, EXTENTS,
       floor(RSSIZE/1024/1024)||'M' RSSIZE,
       floor(OPTSIZE/1024/1024)||'M' OPTSIZE,
       floor(HWMSIZE/1024/1024)||'M' HWMSIZE,
       GETS, WAITS, abs(WRITES) WRITES,
       SHRINKS, EXTENDS, WRAPS, AVESHRINK,
       AVEACTIVE, STATUS
from v\$rollstat t1, v\$rollname t2
where t1.usn=t2.usn
  and name != 'SYSTEM'
order by abs(WRITES) desc
/

   spool off

   exit
EOF

   mailit_or_not "Rollback Information $ORACLE_SID" $mailist

return $?
} 

###-------------------------------------------------------------------------------------
function rpt_pinned_objects
{
   USAGE="Usage: rpt_pinned_objects arg1  (arg1=mailing list)"

   if test "$#" -lt 1
   then
     echo $USAGE
     return 1
   fi

   mailist=$1

   output_var pinned_objects_$mailist.out

   sqlplus -s / <<EOF > /dev/null
   whenever sqlerror exit failure
   set heading on feedback off linesize 132 pagesize 9999

   spool $OUTPUT 

select substr(owner,1,10) OBJ_OWNER,  substr(name,1,40) OBJ_NAME, sharable_mem MEMORY, executions, substr(type,1,15) OBJ_TYPE
from v\$db_object_cache
where kept = 'YES'
order by owner, name
/

   spool off

   exit
EOF

   mailit_or_not "Pinned Objects $ORACLE_SID" $mailist

return $?
} 

###-------------------------------------------------------------------------------------
function rpt_pinnable_objects
{
   USAGE="Usage: rpt_pinnable_objects arg1  (arg1=mailing list)"

   if test "$#" -lt 1
   then
     echo $USAGE
     return 1
   fi

   mailist=$1

   output_var pinnable_objects_$mailist.out

   sqlplus -s / <<EOF > /dev/null
   whenever sqlerror exit failure
   set heading on feedback off linesize 132 pagesize 9999

   spool $OUTPUT 

ttitle center 'OBJECTS THAT ARE PIN CANDIDATES (> 64 K and > 100 executions)' skip1

select substr(owner,1,10) OBJ_OWNER,  substr(name,1,40) OBJ_NAME, sharable_mem MEMORY, executions, substr(type,1,15) OBJ_TYPE
from v\$db_object_cache
where kept = 'NO'
and sharable_mem > 64000
and executions > 100
and type in ('PROCEDURE','PACKAGE','PACKAGE BODY','SEQUENCE','TABLE','TRIGGER','VIEW')
order by owner, name
/

   spool off

   exit
EOF

   mailit_or_not "Pinnable Objects $ORACLE_SID" $mailist

return $?
} 

###-------------------------------------------------------------------------------------
function rpt_reorg_table_info
{
   USAGE="Usage: rpt_reorg_table_info arg1  (arg1=mailing list)"

   if test "$#" -lt 1
   then
     echo $USAGE
     return 1
   fi

   mailist=$1

   output_var reorg_table_info_$mailist.out

   sqlplus -s / <<EOF > /dev/null
   whenever sqlerror exit failure
   set heading on feedback off pagesize 9999

   spool $OUTPUT 

set scan on
set verify off

ttitle center 'TABLES THAT SHOULD BE REORGANIZED' skip1

column "TABLE"     format A32
column "BLOCKS"    heading "BLOCKS|ALLOC./USED" format A11
column could_be    heading "USED IF|SHRINKED"
column pct_used    heading "ACTUAL|PCTUSED"
column advised     heading "MAX|PCTUSED"
column pcts        heading "PCT|FREE/USED" format A9
column pct_chained heading "PCT|CHAINED"
set numwidth 7
--
--  Note that avg_row_len includes overhead
--
select t.owner || '.' || t.TABLE_NAME "TABLE",
       ltrim(to_char(s.blocks)) || '/' || ltrim(to_char(t.blocks)) "BLOCKS",
       ceil((t.avg_row_len * t.num_rows) /
       --
       -- Below is the number of available bytes for storing data per
       -- block when inserting - block size in bytes minus overhead
       -- (fixed + variable parts - around 100 bytes usually) minus
       -- pct free which is kept aside for updates
       --
                ((s.bytes / s.blocks                       -- block size
                   - (fo.fixed_overhead +
                        (t.ini_trans - 1) * vo.type_size)) -- overhead
                 * (100 - t.pct_free) / 100)) could_be,
       ltrim(to_char(t.pct_free)) || '/' || ltrim(to_char(t.PCT_USED)) PCTS,
       floor(100 * ((s.bytes / s.blocks         
                   - (fo.fixed_overhead +
                        (t.ini_trans - 1) * vo.type_size))
                 * (1 - t.pct_free / 100) - t.avg_row_len)
               / (s.bytes / s.blocks - (fo.fixed_overhead + (t.ini_trans - 1)
                    * vo.type_size))) ADVISED,
       decode(t.num_rows, 0, 0,
                          ceil(100 * t.CHAIN_CNT / t.num_rows)) PCT_CHAINED
from dba_tables t,
     dba_segments s,
     (select sum(type_size) fixed_overhead
      from v\$type_size fo
      where fo.component in ('KCB', 'KDB')
      or (fo.component = 'S' and fo.type = 'UB2')
      or (fo.component = 'KTB' and fo.type = 'KTBBH')) fo, -- fixed overhead
     v\$type_size vo   -- variable overhead
where s.OWNER = t.owner
  and s.SEGMENT_NAME = t.TABLE_NAME
  and s.SEGMENT_TYPE = 'TABLE'
  and s.TABLESPACE_NAME = t.TABLESPACE_NAME
  and t.blocks != 0
  --   We list only those tables for which we can probably recover
  --   more than 10% of blocks or 20 blocks, whichever the greatest,
  --   or for which more than 5% or rows are chained
  and (t.blocks > greatest(1.1 * ceil((t.avg_row_len * t.num_rows) /
       ((s.bytes / s.blocks - (fo.fixed_overhead + (t.ini_trans - 1)
                    * vo.type_size)) * (100 - t.pct_free) / 100)),
             20 + ceil((t.avg_row_len * t.num_rows) /
       ((s.bytes / s.blocks - (fo.fixed_overhead + (t.ini_trans - 1)
                    * vo.type_size)) * (100 - t.pct_free) / 100)))
      or t.chain_cnt > 0.05 * t.num_rows)
  /*  and t.owner = decode('p1', '-', t.owner, upper('p1')) */
  and t.owner != 'SYS'
  and vo.component = 'KTB'
  and vo.type = 'KTBIT'
order by t.blocks -
         ceil((t.avg_row_len * t.num_rows) /
             ((s.bytes / s.blocks - (fo.fixed_overhead + (t.ini_trans - 1)
                    * vo.type_size)) * (100 - t.pct_free) / 100)) desc
/

   spool off

   exit
EOF

   mailit_or_not "Tables Needing Reorganization $ORACLE_SID" $mailist

return $?
} 

###-------------------------------------------------------------------------------------
function rpt_reorg_index_info
{
   USAGE="Usage: rpt_reorg_index_info arg1  (arg1=mailing list)"

   if test "$#" -lt 1
   then
     echo $USAGE
     return 1
   fi

   mailist=$1

   output_var reorg_index_info_$mailist.out

   sqlplus -s / <<EOF > /dev/null
   whenever sqlerror exit failure
   set heading on feedback off pagesize 9999

   spool $OUTPUT 

   ttitle center 'INDEXES THAT SHOULD BE REORGANIZED (if BLEVEL is => 4)' skip1

   select index_name, blevel,
        decode(blevel,0,'OK BLEVEL',1,'OK BLEVEL',
        2,'OK BLEVEL',3,'OK BLEVEL',4,'OK BLEVEL','BLEVEL HIGH') OK
   from dba_indexes
   where owner not in ('SYS','SYSTEM')
   and blevel >= 3
   ;

   ---select DEL_LF_ROWS*100/decode(LF_ROWS, 0, 1, LF_ROWS) PCT_DELETED,
   ---    (LF_ROWS-DISTINCT_KEYS)*100/ decode(LF_ROWS,0,1,LF_ROWS) DISTINCTIVENESS
   ---from index_stats
   ---where NAME='&index_name'
   ---;

    ---col name         heading 'Index Name'          format a30
    ---col del_lf_rows  heading 'Deleted|Leaf Rows'   format 99999999
    ---col lf_rows_used heading 'Used|Leaf Rows'      format 99999999
    ---col ibadness     heading '% Deleted|Leaf Rows' format 999.99999

    ---SELECT name,
    ---   del_lf_rows,
    ---   lf_rows - del_lf_rows lf_rows_used,
    ---   to_char(del_lf_rows / (lf_rows)*100,'999.99999') ibadness
    ---FROM index_stats
    ---   where name = upper('&&index_name');

    ---undefine index_name  

   spool off

   exit
EOF

   mailit_or_not "Indexes Needing Reorganization $ORACLE_SID" $mailist

return $?
} 

###-------------------------------------------------------------------------------------
function rpt_enqueue_waits
{
   USAGE="Usage: rpt_enqueue_waits arg1  (arg1=mailing list)"

   if test "$#" -lt 1
   then
     echo $USAGE
     return 1
   fi

   mailist=$1

   output_var enqueue_waits_$mailist.out

   sqlplus -s / <<EOF > /dev/null
   whenever sqlerror exit failure
   set heading on feedback off  pagesize 9999

col sid   format    9999 heading "Sid"
col enq   format      a4 heading "Enq."
col edes  format     a30 heading "Enqueue Name"
col md    format     a10 heading "Lock Mode"
col p2    format 9999999 heading "ID 1"
col p3    format 9999999 heading "ID 2"

   spool $OUTPUT

select sid,
       chr(bitand(p1,-16777216)/16777215)||
       chr(bitand(p1, 16711680)/65535) enq,
       decode(
         chr(bitand(p1,-16777216)/16777215)||chr(bitand(p1, 16711680)/65535),
                'TX','RBS Transaction',
                'TS','Tablespace (temp seg)',
                'TT','Temporary Table',
                'ST','Space Mgt (e.g., uet$, fet$)',
                'UL','User Defined',
         chr(bitand(p1,-16777216)/16777215)||chr(bitand(p1, 16711680)/65535))
         edes,
       decode(bitand(p1,65535),1,'Null',2,'Sub-Share',3,'Sub-Exlusive',
         4,'Share',5,'Share/Sub-Exclusive',6,'Exclusive','Other') md,
       p2,
       p3
from   v\$session_wait
where  event = 'enqueue'
/                                                                        

   spool off

   exit
EOF

   mailit_or_not "Enqueue Waits $ORACLE_SID" $mailist

return $?
}                           

###-------------------------------------------------------------------------------------
function rpt_database_usage
{
   USAGE="Usage: rpt_database_usage arg1  (arg1=mailing list)"

   if test "$#" -lt 1
   then
     echo $USAGE
     return 1
   fi

   mailist=$1

   output_var database_usage_$mailist.out

   sqlplus -s / <<EOF > /dev/null
   whenever sqlerror exit failure
   set heading on feedback off  pagesize 9999

rem Set up environment

set termout off
set pause off
set pages 540
set feedback off
set time off

rem ***************************************************************************

rem send output to a file

   spool $OUTPUT
 
rem ***************************************************************************

rem Print overall heading for report

set heading off

prompt ########################################################################
prompt #               Oracle Database Utilization Report                     #
prompt ########################################################################
prompt
prompt Instance Name:

select value from v\$parameter where name='db_name'
/

prompt
prompt
prompt Date Of This Report:

Column today format a30

select to_char(sysdate,'dd Month YYYY  HH24:MI') today from sys.dual;

prompt
prompt

rem ***************************************************************************

rem Tablespace utilization section

set heading on

prompt ########################################################################
prompt
prompt Tablespace Utilization (Datafile)
prompt

column  "Location"              format A30;
column  "Tablespace Name"       format A15;
column  "Size(M)"               format 999,990;

break on "Tablespace Name" skip 1 nodup;
compute sum of "Size(M)" on "Tablespace Name";

SELECT  tablespace_name "Tablespace Name",
        file_name "Location",
        bytes/1048576 "Size(M)"
FROM sys.dba_data_files
order by tablespace_name
/

prompt
prompt

rem ***************************************************************************

rem Table Sizes section

column Bytes heading Bytes format 99,999,999,999
column tablespace_name heading 'Tablespace Name' format a24
column segment_name heading 'Table Name' format a28
column owner heading 'Owner' format a10

prompt ########################################################################
prompt
prompt Table Sizes Report
prompt

select tablespace_name,segment_name,owner,sum(bytes) Bytes
	from sys.dba_extents
	where owner not in ('SYS','SYSTEM') and segment_type='TABLE'
	group by tablespace_name,owner,segment_name
        order by tablespace_name,bytes desc
/

prompt
prompt

rem ***************************************************************************

rem Index Sizes section

column Bytes heading Bytes format 99,999,999,999
column tablespace_name heading 'Tablespace Name' format a24
column segment_name heading 'Index Name' format a28
column owner heading 'Owner' format a10

prompt ########################################################################
prompt
prompt Index Sizes Report
prompt

select tablespace_name,segment_name,owner,sum(bytes) Bytes
	from sys.dba_extents
	where owner not in ('SYS','SYSTEM') and segment_type='INDEX'
	group by tablespace_name,owner,segment_name
        order by tablespace_name,bytes desc
/

prompt
prompt

rem ***************************************************************************

rem Views section

prompt ########################################################################
prompt
prompt Views Report
prompt

Select owner,view_name
   from sys.dba_views
   where owner not in ('SYS','SYSTEM','PUBLIC')
   order by owner,view_name
/

prompt
prompt

rem ***************************************************************************

rem Packages section

column Bytes heading Bytes format 99,999,999,999
column tablespace_name heading 'Tablespace Name' format a24
column segment_name heading 'Index Name' format a28
column owner heading 'Owner' format a10

prompt ########################################################################
prompt
prompt Packages Report
prompt

select unique(name),owner
   from sys.dba_source
   where type='PACKAGE'
   and owner not in ('SYS','SYSTEM','PUBLIC')
   order by owner,name
/

prompt
prompt

rem ***************************************************************************

rem Object fragmentation section

column owner format a10 heading "Owner"
column segment_name format a30 heading "Object Name"
column segment_type format a9 heading "Table  |Index"
column sum(bytes) format 99,999,999,999 heading "Bytes  |Used"
column count(*) format 999 heading "Extents"
prompt ########################################################################
prompt
prompt Table Fragmentation Report
prompt
select owner,segment_name,segment_type,sum(bytes),count(*) frags
from sys.dba_extents
where owner not in ('SYS','SYSTEM')
having count(*) > 1
group by owner,segment_name,segment_type
order by frags desc
/

prompt
prompt

rem ***************************************************************************

rem Tablespace free segments section

prompt ########################################################################
prompt
prompt Tablespace Free Segments Report
prompt

column tablespace_name heading "Table Space" format a22
column bytes format 99,999,999,999

select free.tablespace_name,free.bytes
	from sys.dba_free_space free
	order by free.tablespace_name,free.bytes
/

prompt
prompt
prompt ########################################################################
prompt #                         END OF REPORT 
prompt ########################################################################
prompt

rem ***************************************************************************

rem Close out SQL*Plus script

   spool off

   exit
EOF

   mailit_or_not "Database Usage Information $ORACLE_SID" $mailist

return $?
}                           


###-------------------------------------------------------------------------------------
function rpt_security_check
{
   USAGE="Usage: rpt_security_check arg1  (arg1=mailing list)"

   if test "$#" -lt 1
   then
     echo $USAGE
     return 1
   fi

   mailist=$1

   output_var security_check_$mailist.out

   sqlplus -s / <<EOF > /dev/null
   whenever sqlerror exit failure
   set heading on feedback off  pagesize 9999

rem Set up environment

set termout off
set pause off
set pages 5400
set feedback off
set time off

rem ***************************************************************************

rem send output to a file

   spool $OUTPUT
 
rem ***************************************************************************

rem Print overall heading for report

set heading off

prompt ########################################################################
prompt #               Oracle Database Security Report                        #
prompt ########################################################################
prompt
prompt Instance Name:

select value from v\$parameter where name='db_name'
/

prompt
prompt
prompt Date Of This Report:

Column today format a30

select to_char(sysdate,'dd Month YYYY  HH24:MI') today from sys.dual;

prompt
prompt

rem ***************************************************************************

rem Profiles section

set heading on

column profile format a15
column resource_name format a30
column limit format a20

prompt ########################################################################
prompt
prompt Profiles
prompt

select profile,resource_name,limit
	from sys.dba_profiles
	order by profile,resource_name
/

prompt
prompt

rem ***************************************************************************

rem System Privileges

prompt ########################################################################
prompt
prompt System Privileges
prompt

select * from sys.dba_sys_privs
	order by grantee,privilege
/

prompt
prompt

rem ***************************************************************************

rem Users

column username format a15
column default_tablespace format a30
column temporary_tablespace format a30

prompt ########################################################################
prompt
prompt Users
prompt

select username,default_tablespace,temporary_tablespace
	from sys.dba_users
	order by username
/

prompt
prompt

rem ***************************************************************************

rem Roles

prompt ########################################################################
prompt
prompt Roles
prompt

select * from sys.dba_roles
	order by role
/

prompt
prompt

rem ***************************************************************************

rem Role Privileges

prompt ########################################################################
prompt
prompt Role Privileges
prompt

select * from sys.dba_role_privs
	order by grantee,granted_role
/

prompt
prompt

rem ***************************************************************************

rem Table Listing

prompt ########################################################################
prompt
prompt Table Listing
prompt

select owner,table_name from sys.dba_tables
	where owner not in ('SYS','SYSTEM')
	order by owner,table_name
/

prompt
prompt

rem ***************************************************************************

rem Table Privileges

column grantee format a18
column table_name format a30
column owner format a10
column privilege format a15

prompt ########################################################################
prompt
prompt Table Privileges
prompt

select grantee,table_name,owner,privilege from sys.dba_tab_privs
	where grantee not in ('SYS','SYSTEM','EXP_FULL_DATABASE')
	order by grantee,table_name
/

prompt
prompt

rem ***************************************************************************

rem Views Listing

prompt ########################################################################
prompt
prompt Views Listing
prompt

select owner,view_name
	from sys.dba_views
	where owner not in ('SYS','SYSTEM')
	order by owner,view_name
/

prompt
prompt


rem ***************************************************************************

rem Synonyms Listing

column owner noprint
column synonym_name format a30
column table_owner format a15
column table_name format a30

prompt ########################################################################
prompt
prompt Public Synonym Listing
prompt

select owner,synonym_name,table_owner,table_name
	from sys.dba_synonyms
	where owner='PUBLIC' and table_owner not in ('SYS','SYSTEM')
	order by synonym_name
/

prompt
prompt

column owner print

rem ***************************************************************************

rem Index Listing

column owner format a10
column index_name format a25
column table_name format a25
column table_owner format a10

prompt ########################################################################
prompt
prompt Index Listing
prompt

select owner,index_name,table_name,table_owner
	from sys.dba_indexes	
	where owner not in ('SYS','SYSTEM')
	order by index_name,table_name
/

prompt
prompt

rem ***************************************************************************

rem Package Listing

column object_name format a30
column object_type format a20
column status noprint

prompt ########################################################################
prompt
prompt Package Listing
prompt

select object_name,object_type,status
	from sys.dba_objects
	where object_type like 'PACKAGE%'
	order by object_name
/

prompt
prompt

rem ***************************************************************************

rem Close out SQL*Plus script

   spool off

   exit
EOF

   mailit_or_not "Security Check $ORACLE_SID" $mailist

return $?
}                           

###-------------------------------------------------------------------------------------
function rpt_analyzed_tables_unanalyed_indexes
{
   USAGE="Usage: rpt_analyzed_tables_unanalyed_indexe arg1  (arg1=mailing list)"

   if test "$#" -lt 1
   then
     echo $USAGE
     return 1
   fi

   mailist=$1

   output_var analyzed_tables_unanalyed_indexes_$mailist.out

   sqlplus -s / <<EOF > /dev/null
   whenever sqlerror exit failure
   set heading on feedback off  pagesize 9999

   spool $OUTPUT

/* ************************************************************* */
/* List analyzed tables with un-analyzed indexes                 */
/*                                                               */
/* Sometimes indexes are re-build for performance and            */
/* maintenance reasons but the assosiated table/index is not     */
/* re-ANALYZED. This can cause servere performance problems.     */
/* This script will catch out tables with indexes that is not    */
/* analyzed.                                                     */
/*                                                               */
/* ************************************************************* */

-- select distinct 'analyze table '||i.table_name||
--                ' estimate statistics sample 25 percent;'
select 'Index '||i.index_name||' not analyzed but table '||
       i.table_name||' is.'
  from user_tables t, user_indexes i
 where t.table_name    =      i.table_name
   and t.num_rows      is not null
   and i.distinct_keys is     null
/

   spool off

   exit
EOF

   mailit_or_not "Analyzed Tables / Unanalyzed Indexes $ORACLE_SID" $mailist

return $?
}

###-------------------------------------------------------------------------------------
function rpt_current_database_transactions
{
   USAGE="Usage: rpt_current_database_transactions arg1  (arg1=mailing list)"

   if test "$#" -lt 1
   then
     echo $USAGE
     return 1
   fi

   mailist=$1 

   output_var current_database_transactions_$mailist.out


   sqlplus -s / <<EOF > /dev/null
   whenever sqlerror exit failure
   set heading on feedback off  pagesize 9999

   spool $OUTPUT

select s.osuser "O/S-User" , s.username "Ora-User", s.sid "Session-ID",s.serial# "Serial",
s.process "Process-ID", s.status "Status", r.name "Rollback", l.name "Obj Locked", l.mode_held "Lock Mode",
t.log_io "Log I/O", t.phy_io "Phy I/O", t.used_ublk "undo blks", t.used_urec "undo recs" ,
st.sql_text "Sql Text" 
from v\$session s, v\$transaction t, v\$rollname r, v\$process p, v\$sqltext st, dba_dml_locks l
where s.taddr = t.addr
and l.session_id = s.sid
and t.xidusn = r.usn 
and p.addr = s.paddr 
and s.sql_address = st.address 
and st.piece = 0 
/

   spool off

   exit
EOF

   mailit_or_not "current_database_transactions $ORACLE_SID" $mailist


return $?
}

###-------------------------------------------------------------------------------------
function rpt_objects_unable_to_get_next_extent
{
   USAGE="Usage: rpt_objects_unable_to_get_next_extent arg1  (arg1=mailing list)"

   if test "$#" -lt 1
   then
     echo $USAGE
     return 1
   fi

   mailist=$1 

   output_var objects_unable_to_get_next_extent_$mailist.out


   sqlplus -s / <<EOF > /dev/null
   whenever sqlerror exit failure
   set heading on feedback off  pagesize 9999

   spool $OUTPUT

set serverout on
set feed off
DECLARE

M_OWNER     dba_segments.owner%type;
M_SEGMENT_NAME  dba_segments.segment_name%type;
M_TYPE      dba_segments.segment_name%type;
M_TSNAME    dba_segments.segment_name%type;
M_BYTES     dba_segments.bytes%type;
M_NEXT      dba_segments.next_extent%type;
M_PCTINC    dba_segments.pct_increase%type;
NEXT_NEEDED1    number;
NEXT_NEEDED1_MB number;
NEXT_NEEDED2    number;
NEXT_NEEDED2_MB number;
LARGEST_HOLE    number;
LARGEST_HOLE_MB number;
ROW_COUNT   number := 0;

CURSOR      get_segment_name is
        select  rpad(owner,12,' '),
            rpad(segment_name,20,' '),
            rpad(segment_type,13,' '),
            tablespace_name,
            bytes,next_extent, pct_increase 
        from dba_segments
        order by tablespace_name;

BEGIN

    dbms_output.enable(1000000);
    dbms_output.put_line
    ('List of objects that will fail to allocate next/next+1 extent.');
    dbms_output.put_line
    ('Obj Type     Owner       Name                NEXT MB  2nd NEXT Free');
    dbms_output.put_line(lpad('_',67,'_'));

    open get_segment_name;
    LOOP
      fetch get_segment_name into
      m_owner,m_segment_name,m_type,m_tsname,m_bytes,m_next,m_pctinc;

      select max(bytes) into largest_hole from dba_free_space
      where tablespace_name=M_TSNAME;

      if m_pctinc = 0 then m_pctinc := 100;
      end if;
 
      exit when get_segment_name%NOTFOUND;

      next_needed1    := m_next;
      next_needed2    := m_next + m_next*(m_pctinc/100);
      next_needed1_MB := round(next_needed1/(1024*1024));
      next_needed2_MB := round(next_needed2/(1024*1024));
      largest_hole_MB := round(largest_hole/(1024*1024));

      select max(bytes) into largest_hole from user_free_space
      where tablespace_name=M_TSNAME;

     if (
        next_needed1 > largest_hole 
        OR 
        next_needed2 > largest_hole
        )
     then 
        row_count := row_count +1 ;
        dbms_output.put_line
        (M_TYPE||M_OWNER||M_SEGMENT_NAME||
        rpad(next_needed1_MB,9,' ')||
        rpad(next_needed2_MB,9,' ')||
        rpad(largest_hole_MB,9,' '));
     end if;
     
    END LOOP;
    close get_segment_name;
END;
/
   spool off

   exit
EOF

   mailit_or_not "Objects Unable To Get Next Extent $ORACLE_SID" $mailist


return $?
}

###-------------------------------------------------------------------------------------
function rpt_redundent_index_analysis
{
   USAGE="Usage: rpt_redundent_index_analysis arg1  (arg1=mailing list)"

   if test "$#" -lt 1
   then
     echo $USAGE
     return 1
   fi

   mailist=$1 

   output_var redudent_index_analysis_$mailist.out


   sqlplus -s / <<EOF > /dev/null
   whenever sqlerror exit failure
   set heading on feedback off  pagesize 9999

   spool $OUTPUT

set linesize 165
set pagesize 54
set feedback off
set trimspool on

COLUMN table_owner      FORMAT a10               HEADING  'Table|Owner'
COLUMN table_name       FORMAT a30 word_wrapped  HEADING  'Table Name'
COLUMN index_name       FORMAT a30 word_wrapped  HEADING  'Index Name'
COLUMN index_cols       FORMAT a30 word_wrapped  HEADING  'Index Columns'
column redun_index      FORMAT a30 word_wrapped  HEADING  'Redundant Index'
COLUMN redun_cols       FORMAT a30 word_wrapped  HEADING  'Redundant Columns'

clear breaks

break on owner           skip 0

TTITLE -
       center 'Redudnant Index Analysis'  skip 1 -
       center '~~~~~~~~~~~~~~~~~~~~~~~~'  skip 2

SELECT ai.table_owner  table_owner,
       ai.table_name   table_name,
       ai.index_name   index_name,
       ai.columns      index_cols,
       bi.index_name   redun_index,
       bi.columns      redun_cols
FROM 
( SELECT a.table_owner,
         a.table_name, 
         a.index_name, 
             MAX(DECODE(column_position, 1,
SUBSTR(column_name,1,30),NULL)) || 
             MAX(DECODE(column_position, 2,',
'||SUBSTR(column_name,1,30),NULL)) || 
             MAX(DECODE(column_position, 3,',
'||SUBSTR(column_name,1,30),NULL)) || 
             MAX(DECODE(column_position, 4,',
'||SUBSTR(column_name,1,30),NULL)) || 
             MAX(DECODE(column_position, 5,',
'||SUBSTR(column_name,1,30),NULL)) || 
             MAX(DECODE(column_position, 6,',
'||SUBSTR(column_name,1,30),NULL)) || 
             MAX(DECODE(column_position, 7,',
'||SUBSTR(column_name,1,30),NULL)) || 
             MAX(DECODE(column_position, 8,',
'||SUBSTR(column_name,1,30),NULL)) || 
             MAX(DECODE(column_position, 9,',
'||SUBSTR(column_name,1,30),NULL)) || 
             MAX(DECODE(column_position,10,',
'||SUBSTR(column_name,1,30),NULL)) || 
             MAX(DECODE(column_position,11,',
'||SUBSTR(column_name,1,30),NULL)) || 
             MAX(DECODE(column_position,12,',
'||SUBSTR(column_name,1,30),NULL)) || 
             MAX(DECODE(column_position,13,',
'||SUBSTR(column_name,1,30),NULL)) || 
             MAX(DECODE(column_position,14,',
'||SUBSTR(column_name,1,30),NULL)) || 
             MAX(DECODE(column_position,15,',
'||SUBSTR(column_name,1,30),NULL)) || 
             MAX(DECODE(column_position,16,',
'||SUBSTR(column_name,1,30),NULL)) columns
    FROM dba_ind_columns a
   WHERE a.index_owner not in ('SYS','SYSTEM')
   GROUP BY a.table_owner,
            a.table_name,
            a.index_owner,
            a.index_name) ai, 
( SELECT b.table_owner,
         b.table_name,
         b.index_name, 
             MAX(DECODE(column_position, 1,
SUBSTR(column_name,1,30),NULL)) || 
             MAX(DECODE(column_position, 2,',
'||SUBSTR(column_name,1,30),NULL)) || 
             MAX(DECODE(column_position, 3,',
'||SUBSTR(column_name,1,30),NULL)) || 
             MAX(DECODE(column_position, 4,',
'||SUBSTR(column_name,1,30),NULL)) || 
             MAX(DECODE(column_position, 5,',
'||SUBSTR(column_name,1,30),NULL)) || 
             MAX(DECODE(column_position, 6,',
'||SUBSTR(column_name,1,30),NULL)) || 
             MAX(DECODE(column_position, 7,',
'||SUBSTR(column_name,1,30),NULL)) || 
             MAX(DECODE(column_position, 8,',
'||SUBSTR(column_name,1,30),NULL)) || 
             MAX(DECODE(column_position, 9,',
'||SUBSTR(column_name,1,30),NULL)) || 
             MAX(DECODE(column_position,10,',
'||SUBSTR(column_name,1,30),NULL)) || 
             MAX(DECODE(column_position,11,',
'||SUBSTR(column_name,1,30),NULL)) || 
             MAX(DECODE(column_position,12,',
'||SUBSTR(column_name,1,30),NULL)) || 
             MAX(DECODE(column_position,13,',
'||SUBSTR(column_name,1,30),NULL)) || 
             MAX(DECODE(column_position,14,',
'||SUBSTR(column_name,1,30),NULL)) || 
             MAX(DECODE(column_position,15,',
'||SUBSTR(column_name,1,30),NULL)) || 
             MAX(DECODE(column_position,16,',
'||SUBSTR(column_name,1,30),NULL)) columns
    FROM dba_ind_columns b
   GROUP BY b.table_owner,
            b.table_name,
            b.index_owner,
            b.index_name ) bi
WHERE ai.table_owner     = bi.table_owner
  AND ai.table_name      = bi.table_name
  AND ai.columns        LIKE bi.columns || ',%'
  AND ai.columns        <> bi.columns
ORDER BY ai.table_owner,
         ai.table_name,
         bi.index_name
/
ttitle off
clear breaks
clear columns
set linesize 96
set pagesize 60
set feedback on

   spool off

   exit
EOF

   mailit_or_not "Redundent Index Analysis $ORACLE_SID" $mailist


return $?
}




############################################################
####  MONITOR DATABASE FUNCTIONS
############################################################

###-------------------------------------------------------------------------------------
function mon_tablespace_fragmentation_index
{
   USAGE="Usage: mon_tablespace_fragmentation_index arg1  (arg1=threshold)"

   if test "$#" -lt 1
   then
     echo $USAGE
     return 1
   fi

   threshold=$1 

   OUTPUT=$SCRIPTS/out/montemp_$ORACLE_SID.out
   OUTPUT_APPEND=$SCRIPTS/out/monitor_$ORACLE_SID.out


   sqlplus -s / <<EOF > /dev/null
   whenever sqlerror exit failure
   set heading on feedback off  pagesize 9999

   spool $OUTPUT

---
---  Display Tablespace Fragmentation Index
---

prompt
prompt ========================================
prompt   Tablespace Fragmentation Index Listing
prompt   under the threshold of $threshold%
prompt ========================================
prompt
column  "Tablespace Name"       format A15;
column  "FSFI"               format 999,990;

SELECT
     tablespace_name,
     sqrt(max(blocks)/sum(blocks)) *
     (100/sqrt(sqrt(count(blocks)))) fsfi
FROM dba_free_space
WHERE tablespace_name not like 'RB%'
AND   tablespace_name not like 'TEM%'
GROUP BY
     tablespace_name
HAVING (sqrt(max(blocks)/sum(blocks)) * (100/sqrt(sqrt(count(blocks)))) <= $threshold)
ORDER BY 1
/

   spool off

   exit
EOF

cat $OUTPUT >> $OUTPUT_APPEND
rm $OUTPUT

return $?
}

###-------------------------------------------------------------------------------------
function mon_tablespace_freespace
{
   USAGE="Usage: mon_tablespace_freespace arg1  (arg1=threshold)"

   if test "$#" -lt 1
   then
     echo $USAGE
     return 1
   fi

   threshold=$1 

   OUTPUT=$SCRIPTS/out/montemp_$ORACLE_SID.out
   OUTPUT_APPEND=$SCRIPTS/out/monitor_$ORACLE_SID.out


   sqlplus -s / <<EOF > /dev/null
   whenever sqlerror exit failure
   set heading on feedback off  linesize 120 pagesize 9999

   spool $OUTPUT

---
---  Display Tablespace Freespace
---

prompt
prompt ========================================
prompt   Tablespace Freespace Listing
prompt   under the threshold of $threshold
prompt ========================================
prompt
column  "Tablespace Name"       format A15;
column  "Total Space"           format 9,999,999,990;
column  "Max Freespace"         format 9,999,999,990;
column  "Free Blocks"           format 999,990;
column  "Total FreeSpace"       format 9,999,999,990;
column  "Percent Free"          format 990;


select TSPACE_NAME "Tablespace Name",
       TOTAL_SPACE "Total Space",
       MAX_FREE_SPACE "Max Freespace",
       COUNT_FREE_BLOCKS "Free Blocks",
       TOTAL_FREE_SPACE "Total Freespace",
       100*TOTAl_FREE_SPACE/TOTAL_SPACE "Percent Free"
  from
      (select Tablespace_Name TSPACE_NAME,
              SUM(Bytes)/1024 TOTAL_SPACE
         from DBA_DATA_FILES
        group by Tablespace_Name),
      (select Tablespace_Name FS_TS_NAME,
              MAX(Bytes)/1024  AS MAX_FREE_SPACE,
              COUNT(Blocks)  AS COUNT_FREE_BLOCKS,
              SUM(Bytes)/1024 AS TOTAL_FREE_SPACE
         from DBA_FREE_SPACE
        group by Tablespace_Name)
 where TSPACE_NAME = FS_TS_NAME
   and (100*TOTAl_FREE_SPACE/TOTAL_SPACE) < $threshold
   and (TSPACE_NAME != 'RBS')
 order by 100*TOTAL_FREE_SPACE/TOTAL_SPACE desc
/

   spool off

   exit
EOF

cat $OUTPUT >> $OUTPUT_APPEND
rm $OUTPUT

return $?
}

###-------------------------------------------------------------------------------------
function mon_segment_fragmentation_index
{
   USAGE="Usage: mon_segment_fragmentation_index arg1  (arg1=threshold)"

   if test "$#" -lt 1
   then
     echo $USAGE
     return 1
   fi

   threshold=$1 

   OUTPUT=$SCRIPTS/out/montemp_$ORACLE_SID.out
   OUTPUT_APPEND=$SCRIPTS/out/monitor_$ORACLE_SID.out


   sqlplus -s / <<EOF > /dev/null
   whenever sqlerror exit failure
   set heading on feedback off  linesize 120 pagesize 9999

   spool $OUTPUT

---
---  Display Segment Fragmentation Index
---

prompt
prompt ========================================
prompt   Segment Fragmentation Index Listing
prompt   over the threshold of $threshold
prompt ========================================
prompt
column  "Segment Name"       format A15;
column  "FSFI"               format 999,990;

SELECT
     substr(segment_name,1,40) "Segment Name",
     sqrt(max(blocks)/sum(blocks)) *
     (100/sqrt(sqrt(count(blocks)))) "FSFI"
FROM dba_segments
---WHERE segment_name not like 'RB%'
---AND   segment_name not like 'TEM%'
GROUP BY
     segment_name
HAVING (sqrt(max(blocks)/sum(blocks)) * (100/sqrt(sqrt(count(blocks)))) <= $threshold)
ORDER BY 1
/

   spool off

   exit
EOF

cat $OUTPUT >> $OUTPUT_APPEND
rm $OUTPUT

return $?
}

###-------------------------------------------------------------------------------------
function mon_segments_near_maxextents
{
   USAGE="Usage: mon_segments_near_maxextents arg1  (arg1=threshold)"

   if test "$#" -lt 1
   then
     echo $USAGE
     return 1
   fi

   threshold=$1 

   OUTPUT=$SCRIPTS/out/montemp_$ORACLE_SID.out
   OUTPUT_APPEND=$SCRIPTS/out/monitor_$ORACLE_SID.out


   sqlplus -s / <<EOF > /dev/null
   whenever sqlerror exit failure
   set heading on feedback off  linesize 120 pagesize 9999

   spool $OUTPUT

---
---  Display Segments Near MaxExtents
---

prompt
prompt ========================================
prompt   Segments Near MaxExtents Listing
prompt   over the threshold of $threshold
prompt ========================================
prompt
column  "Segment Name"       format A15;
column  "Segment Type"       format A15;
column  "Extent Count"       format 9,990;
column  "Max Extents"        format 9,990;
column  "Extent Diff"        format 9,990;

select
  owner||'.'||segment_name              "Segment Name",
  segment_type                          "Segment Type",
  extents                               "Extent Count",
  max_extents                           "Max Extents",
  max_extents-extents                   "Extent Diff"
from
  dba_segments
where
  (max_extents-extents <= $threshold)
and (segment_type != 'CACHE')
and (segment_type != 'ROLLBACK')
order by
  max_extents-extents    desc
/

   spool off

   exit
EOF

cat $OUTPUT >> $OUTPUT_APPEND
rm $OUTPUT

return $?
}

###-------------------------------------------------------------------------------------
function mon_segments_inadequate_room
{
   USAGE="Usage: mon_segments_inadequate_room arg1  (arg1=threshold)"

   if test "$#" -lt 1
   then
     echo $USAGE
     return 1
   fi

   threshold=$1 

   OUTPUT=$SCRIPTS/out/montemp_$ORACLE_SID.out
   OUTPUT_APPEND=$SCRIPTS/out/monitor_$ORACLE_SID.out


   sqlplus -s / <<EOF > /dev/null
   whenever sqlerror exit failure
   set heading on feedback off  linesize 120 pagesize 9999

   spool $OUTPUT

---
---  Display Segments with inadequate room
---

prompt
prompt ========================================
prompt   Segments Inadequate Room Listing
prompt ========================================
prompt
column  "Segment Name"       format A42;
column  "Segment Type"       format A12;
column  "Tablespace Name"    format A20;
column  "Next Extent"        format 9999999999;
column  "Max Extent"         format 9999999999;

select
        a.owner||'.'||a.segment_name "Segment Name",
        a.segment_type "Segment Type",
        b.tablespace_name "Tablespace Name",
        decode(a.extent_id,0,b.next_extent,
               a.bytes*(1+b.pct_increase/100)) "Next Extent",
        freesp.largest "Max Extent"
from    dba_extents a,
        dba_segments b,
        (select tablespace_name, max(bytes) largest
         from dba_free_space
         group by tablespace_name) freesp
where   a.owner=b.owner
and     a.segment_name=b.segment_name
and     a.segment_type=b.segment_type
and     a.extent_id = b.extents - 1
and     b.tablespace_name = freesp.tablespace_name   
and     b.tablespace_name = a.tablespace_name
and     ((a.extent_id = 0 and b.next_extent > freesp.largest)
          or
         (a.extent_id <> 0 and a.bytes*(1+b.pct_increase/100)
                                         > freesp.largest))
and     b.tablespace_name not like 'TEMP%'
order by 3,2,1 
/

   spool off

   exit
EOF

cat $OUTPUT >> $OUTPUT_APPEND
rm $OUTPUT

return $?
}

###-------------------------------------------------------------------------------------
function mon_segments_percent_used
{
   USAGE="Usage: mon_segments_percent_used arg1  (arg1=threshold)"

   if test "$#" -lt 1
   then
     echo $USAGE
     return 1
   fi

   threshold=$1 

   OUTPUT=$SCRIPTS/out/montemp_$ORACLE_SID.out
   OUTPUT_APPEND=$SCRIPTS/out/monitor_$ORACLE_SID.out


   sqlplus -s / <<EOF > /dev/null
   whenever sqlerror exit failure
   set heading on feedback off  linesize 120 pagesize 9999

   spool $OUTPUT

---
---  Display Segments percent used
---

prompt
prompt ========================================
prompt   Segments Percent Used Listing
prompt   over the threshold of $threshold
prompt ========================================
prompt
column  "Segment Name"       format A15;
column  "Tablespace Name"    format A15;
column  "Extent Count"       format 9,990;
column  "Next Extent"        format 9,990;
column  "Max Extent"         format 9,990;

select
        owner owner,
        segment_name segname,
        segment_type
from sys.DBA_SEGMENTS
where segment_type not in ('ROLLBACK','CACHE','TEMPORARY')
order by owner, segment_name, segment_type
/

   spool off

   exit
EOF

cat $OUTPUT >> $OUTPUT_APPEND
rm $OUTPUT

return $?
}

###-------------------------------------------------------------------------------------
function mon_invalid_objects_over_threshold
{
   USAGE="Usage: mon_invalid_objects_over_threshold arg1  (arg1=threshold)"

   if test "$#" -lt 1
   then
     echo $USAGE
     return 1
   fi

   threshold=$1 

   OUTPUT=$SCRIPTS/out/montemp_$ORACLE_SID.out
   OUTPUT_APPEND=$SCRIPTS/out/monitor_$ORACLE_SID.out


   sqlplus -s / <<EOF > /dev/null
   whenever sqlerror exit failure
   set heading off feedback off  linesize 120 pagesize 9999

   spool $OUTPUT

---
---  Display Invalid Objects Over Threshold
---

select DBNAME || ' has ' || INVALID_CNT || ' INVALID OBJECTS,  maximum threshold is ' || $threshold
from dual,
(select count(*) INVALID_CNT from dba_objects where status = 'INVALID'),
(select name DBNAME from v\$database)
where INVALID_CNT > $threshold
/


   spool off

   exit
EOF

cat $OUTPUT >> $OUTPUT_APPEND
rm $OUTPUT

return $?
}

###-------------------------------------------------------------------------------------
function mon_pinned_objects_under_threshold
{
   USAGE="Usage: mon_pinned_objects_under_threshold arg1  (arg1=threshold)"

   if test "$#" -lt 1
   then
     echo $USAGE
     return 1
   fi

   threshold=$1 

   OUTPUT=$SCRIPTS/out/montemp_$ORACLE_SID.out
   OUTPUT_APPEND=$SCRIPTS/out/monitor_$ORACLE_SID.out


   sqlplus -s / <<EOF > /dev/null
   whenever sqlerror exit failure
   set heading off feedback off  linesize 120 pagesize 9999

   spool $OUTPUT

---
---  Display Pinned Objects Under Threshold
---

select DBNAME || ' has ' || PINNED_CNT || ' PINNED OBJECTS,  minimum threshold is ' || $threshold
from dual,
(select count(*) PINNED_CNT from v\$db_object_cache where kept = 'YES'),
(select name DBNAME from v\$database)
where PINNED_CNT > $threshold
/

   spool off

   exit
EOF

cat $OUTPUT >> $OUTPUT_APPEND
rm $OUTPUT

return $?
}

###-------------------------------------------------------------------------------------
function mon_sessions_blocking_sessions
{
   USAGE="Usage: mon_sessions_blocking_sessions NONE"

#   if test "$#" -lt 1
#   then
#     echo $USAGE
#     return 1
#   fi

#   threshold=$1 

   OUTPUT=$SCRIPTS/out/montemp_$ORACLE_SID.out
   OUTPUT_APPEND=$SCRIPTS/out/monitor_$ORACLE_SID.out


   sqlplus -s / <<EOF > /dev/null
   whenever sqlerror exit failure
   set heading on feedback off  linesize 120 pagesize 9999

   spool $OUTPUT

---
---  Display Sessions Holding Other Sessions
---

prompt
prompt =========================================
prompt   Sessions Holding Other Sessions Listing
prompt =========================================
prompt
column  "Holding Session"    format 9,990;
column  "SPID"               format 9,990;
column  "Waiting Session"    format 9,990;

select w.holding_session "Holding Session",
       p.spid "SPID",
       w.waiting_session "Waiting Session"
from dba_waiters w, v\$process p
where w.holding_session = p.pid(+)
/

   spool off

   exit
EOF

cat $OUTPUT >> $OUTPUT_APPEND
rm $OUTPUT

return $?
}

###-------------------------------------------------------------------------------------
function mon_connections_over_threshold
{
   USAGE="Usage: mon_connections_over_threshold arg1  (arg1=threshold)"

   if test "$#" -lt 1
   then
     echo $USAGE
     return 1
   fi

   threshold=$1 

   OUTPUT=$SCRIPTS/out/montemp_$ORACLE_SID.out
   OUTPUT_APPEND=$SCRIPTS/out/monitor_$ORACLE_SID.out


   sqlplus -s / <<EOF > /dev/null
   whenever sqlerror exit failure
   set heading on feedback off  linesize 120 pagesize 9999

   spool $OUTPUT

---
---  Display Connections Over Threshold
---

prompt
prompt =========================================
prompt   Connections Over Threshold Listing
prompt   over the threshold of $threshold
prompt =========================================
prompt
column  "Machine"            format A15;
column  "User Name"          format A15;
column  "Logon"              format A15;
column  "Duration (Hrs)"     format 9,990;

select substr(machine,1,20)"MACHINE",
 substr(osuser,1,10) "USERNAME",
 substr(to_char(logon_time, 'MM-DD-YYYY,HH24:MI'),1,16) "LOGON",
 to_char((sysdate - logon_time) * 1440 / 60, '9999.99') "DURATION (Hrs)"
from v\$session
where (sysdate - logon_time >= (60 * $threshold / 1440))
and osuser not like '%ora%'
and UPPER(machine) not like ('S%')
order by machine
/

   spool off

   exit
EOF

cat $OUTPUT >> $OUTPUT_APPEND
rm $OUTPUT

return $?
}

###-------------------------------------------------------------------------------------
function mon_security_violations
{
   USAGE="Usage: mon_security_violations arg1  (arg1=NONE)"

#   if test "$#" -lt 1
#   then
#     echo $USAGE
#     return 1
#   fi

   threshold=$1 

   OUTPUT=$SCRIPTS/out/montemp_$ORACLE_SID.out
   OUTPUT_APPEND=$SCRIPTS/out/monitor_$ORACLE_SID.out


   sqlplus -s / <<EOF > /dev/null
   whenever sqlerror exit failure
   set heading on feedback off  linesize 120 pagesize 9999

   spool $OUTPUT

---
---  Display Security Violations
---

prompt
prompt =========================================
prompt   Security Violations Listing
prompt =========================================
prompt
column  "User Name"          format A15;
column  "OS User"            format A15;
column  "Machine"            format A15;

select substr(username,1,20) "User Name", substr(osuser,1,10) "OS User", substr(machine,1,10) "Machine"
from v\$session
where UPPER(substr(osuser,2,6)) <> UPPER(substr(machine,2,6))
and UPPER(substr(osuser,2,6)) <> UPPER(substr(machine,3,6))
and UPPER(substr(osuser,2,6)) <> UPPER(substr(machine,4,6))
and UPPER(substr(osuser,2,6)) <> UPPER(substr(machine,5,6))
and UPPER(substr(osuser,2,6)) <> UPPER(substr(machine,6,6))
and UPPER(substr(osuser,2,6)) <> UPPER(substr(machine,7,6))
and UPPER(osuser) not like '%ORA%'

and UPPER(username) not in ('BATCHMGR')
and UPPER(machine) not like ('S%')
/

   spool off

   exit
EOF

cat $OUTPUT >> $OUTPUT_APPEND
rm $OUTPUT

return $?
}

###-------------------------------------------------------------------------------------
function mon_space_general
{
   USAGE="Usage: mon_space_general arg1  (arg1=NONE)"

#   if test "$#" -lt 1
#   then
#     echo $USAGE
#     return 1
#   fi

   threshold=$1 

   OUTPUT="$FS_FOR_OUTPUTS/$ORACLE_SID/space/spacemon.out_$DATETIME"

   sqlplus -s / <<EOF > /dev/null
   whenever sqlerror exit failure
   set heading on feedback off  pagesize 9999

   spool $OUTPUT
prompt
prompt ======================================
prompt   TABLESPACE / ROLLBACK LISTING
prompt =====================================
prompt
prompt
column 	"Location"		format A30;
column	"Tablespace Name"	format A15;
column	"Size(M)"		format 999,990;

break on "Tablespace Name" skip 1 nodup;
compute sum of "Size(M)" on "Tablespace Name";

SELECT	tablespace_name "Tablespace Name",
	file_name "Location",
	bytes/1048576 "Size(M)"	
FROM sys.dba_data_files
order by tablespace_name;

prompt
prompt ======================================
prompt   REDO LOG LISTING
prompt =====================================
prompt
prompt
column  "Group"         format 999;
column  "File Location" format A40;
column  "Bytes (K)"     format 99,990;

break on "Group" skip 1 nodup;


select  a.group# "Group",
        b.member "File Location",
        a.bytes/1024 "Bytes (K)"
from    v\$log a,
        v\$logfile b
where a.group# = b.group#
order by 1,2;

prompt
prompt ======================================
prompt   ROLLBACK LISTING
prompt =====================================
prompt
prompt
column  "Segment Name"  format A15;
column  "Tablespace"    format A15;
Column  "Initial (K)"   Format 99,990;
Column  "Next (K)"      Format 99,990;
column  "Min Ext."      FORMAT 990;
column  "Max Ext."      FORMAT 9,990;
column  "Status"        Format A7;

select  segment_name "Segment Name",
        tablespace_name "Tablespace",
        initial_extent/1024 "Initial (K)",
        next_extent/1024 "Next (K)",
        min_extents "Min Ext.",
        max_extents "Max Ext.",
        status "Status"
from    sys.dba_rollback_segs
order by tablespace_name,
        segment_name;
rem
rem  This script provides information on the location/path, file name,
rem  size and physical I/Os (if applicable) of all the Oracle files
rem  (database, control and redo log) in an Oracle/UNIX platform.
rem
rem
set pages 999

prompt
prompt ======================================
prompt   File Map Listing
prompt =====================================
prompt
prompt
col path  format a20     heading 'Path'
col fname format a15     heading 'File Name'
col fsize format 999b    heading 'M bytes'
col pr    format 99999999b heading 'Phy. Reads'
col pw    format 999999b heading 'Phy. Writes'
break on path skip 1

select substr(name,1,instr(name, '/', -1)-1 ) path,
       substr(name,instr(name, '/', -1)+1 )  fname,
       bytes/1048576  fsize,
       phyrds pr,
       phywrts pw
  from v\$datafile df, v\$filestat fs
 where df.file# = fs.file#
UNION
select substr(name,1,instr(name, '/', -1)-1 ) path,
       substr(name,instr(name, '/', -1)+1 ) fname,
       0 fsize,
       0 pr,
       0 pw
  from v\$controlfile
UNION
select substr(lgf.member,1,instr(lgf.member,'/', -1)-1) path,
       substr(lgf.member,instr(lgf.member, '/', -1)+1 ) fname,
       lg.bytes/1048576 fsize,
       0 pr,
       0 pw
  from v\$logfile lgf, v\$log lg
 where lgf.group# = lg.group#
order by 1,2;

set pagesize 300 linesize 132

prompt
prompt ======================================
prompt   SPACE AVAILABLE IN TABLESPACES
prompt =====================================
prompt
prompt
column sumb format 999,999,999,999,999
column extents forma 9999
column bytes format 999,999,999
column largest format 999,999,999
column Tot_Size format 9,999,999,999
column Tot_Free format 9,999,999,999
column Pct_Free format 999,999,999
column Chunks_Free format 999,999,999
column Max_Free format 9,999,999,999
set echo off

select a.tablespace_name,sum(a.tots) Tot_Size,
sum(a.sumb) Tot_Free,
sum(a.sumb)*100/sum(a.tots) Pct_Free,
sum(a.largest) Max_Free,sum(a.chunks) Chunks_Free
from
(
select tablespace_name,0 tots,sum(bytes) sumb,
max(bytes) largest,count(*) chunks
from dba_free_space a
group by tablespace_name
UNION
select tablespace_name,sum(bytes) tots,0,0,0 from
dba_data_files
group by tablespace_name) a
group by a.tablespace_name;

prompt
prompt ======================================
prompt   SEGMENTS WITH MORE THAN 50 EXTENTS
prompt =====================================
prompt
prompt
column owner format a15
column segment_name format a30

select owner,segment_name,extents,bytes ,
max_extents,next_extent
from  dba_segments
where segment_type in ('TABLE','INDEX') and extents>50
order by owner,segment_name;

prompt
prompt ======================================
prompt   ?
prompt =====================================
prompt
prompt
column Tablespace_Name format A20
column Pct_Free format 999.99

select Tablespace_Name,
Max_Blocks,
Count_Blocks,
Sum_Free_Blocks,
100*Sum_Free_Blocks/Sum_Alloc_Blocks AS Pct_Free
from
(select Tablespace_Name, SUM(Blocks) Sum_Alloc_Blocks
from DBA_DATA_FILES
group by Tablespace_Name),
   (select Tablespace_Name FS_TS_NAME,
   MAX(Blocks)  AS Max_Blocks,
   COUNT(Blocks)  AS Count_Blocks,
   SUM(Blocks) AS Sum_Free_Blocks
   from DBA_FREE_SPACE
   group by Tablespace_Name)
where Tablespace_Name = FS_TS_NAME;

/

   spool off

   exit
EOF


return $?
}

############################################################
####  OLTP FUNCTIONS
############################################################

###-------------------------------------------------------------------------------------
function oltp_force_logfile_switch
{
   USAGE="Usage: oltp_force_logfile_switch arg1  (arg1=NONE)"


#   if test "$#" -lt 1
#   then
#     echo $USAGE
#     return 1
#   fi

   threshold=$1 

   output_var oltp_logfile_switch_$ORACLE_SID.out

   sqlplus -s / <<EOF > /dev/null
   whenever sqlerror exit failure
   set heading on feedback off  linesize 120 pagesize 9999

   spool $OUTPUT

---
---  Force a Logfile Switch creating a new Archive logfile
---
declare

     cur     Integer;                -- DSQL: Cursor ID
     ret     Integer;                -- DSQL: Return Value

     v_command        VARCHAR2(200);

begin

        v_command := 'alter system switch logfile';
   
        cur := dbms_sql.open_cursor;
        dbms_sql.parse(cur, v_command, dbms_sql.v7);    
        ret := dbms_sql.execute(cur);
        dbms_sql.close_cursor(cur);

end;
/

   spool off

   exit
EOF

remove_file $OUTPUT

return $?
}

###-------------------------------------------------------------------------------------
function oltp_flush_shared_pool
{
   USAGE="Usage: oltp_flush_shared_pool arg1  (arg1=NONE)"

#   if test "$#" -lt 1
#   then
#     echo $USAGE
#     return 1
#   fi

   threshold=$1 

   output_var oltp_flush_shared_pool_$ORACLE_SID.out

   sqlplus -s / <<EOF > /dev/null
   whenever sqlerror exit failure
   set heading on feedback off  linesize 120 pagesize 9999
   set serveroutput on;

   spool $OUTPUT
   /*
   *********************************************************
   *                                                       *
   * TITLE        : Shared Pool Estimation                 *
   * CATEGORY     : Information, Utility                   *
   * SUBJECT AREA : Shared Pool                            *
   * DESCRIPTION  : Estimates shared pool utilization      *
   *  based on current database usage. This should be      *
   *  run during peak operation, after all stored          *
   *  objects i.e. packages, views have been loaded.       *
   *                                                       *
   *                                                       *
   ********************************************************/
   Rem If running MTS uncomment the mts calculation and output
   Rem commands.    

   ---
   ---  Flushes Oracles Memory Shared Pool
   ---
declare

     cur     Integer;                -- DSQL: Cursor ID
     ret     Integer;                -- DSQL: Return Value

     v_command        VARCHAR2(200);
     object_mem number;
     shared_sql number;
     cursor_mem number;
     mts_mem number;
     used_pool_size number;
     actual_used_pool_size number;
     free_mem number;
     used_space_SPR number;
     pool_size varchar2(512); -- same as V$PARAMETER.VALUE

begin
     -- >>> Stored objects (packages, views)
     select sum(sharable_mem) into object_mem from v\$db_object_cache;

     -- >>> Shared SQL -- need to have additional memory if dynamic SQL used
     select sum(sharable_mem) into shared_sql from v\$sqlarea;

     -- >>> User Cursor Usage -- run this during peak usage.
     --  assumes 250 bytes per open cursor, for each concurrent user.
     select sum(250*users_opening) into cursor_mem from v\$sqlarea;

     -- For a test system -- get usage for one user, multiply by # users
     -- select (250 * value) bytes_per_user
     -- from v\$sesstat s, v\$statname n
     -- where s.statistic# = n.statistic#
     -- and n.name = 'opened cursors current'
     -- and s.sid = 25;  -- where 25 is the sid of the process

     -- MTS memory needed to hold session information for shared server users
     -- This query computes a total for all currently logged on users (run
     --  during peak period). Alternatively calculate for a single user and
     --  multiply by # users.
     select sum(value) into mts_mem from v\$sesstat s, v\$statname n
            where s.statistic#=n.statistic#
            and n.name='session uga memory max';

     -- Free (unused) memory in the SGA: gives an indication of how much memory
     -- is being wasted out of the total allocated.
     select bytes into free_mem from v\$sgastat
             where name = 'free memory';

     -- For non-MTS add up object, shared sql, cursors and 20% overhead.
     used_pool_size := round(1.2*(object_mem+shared_sql+cursor_mem));

     -- For MTS mts contribution needs to be included (comment out previous line)
     -- used_pool_size := round(1.2*(object_mem+shared_sql+cursor_mem+mts_mem));

     select value into pool_size from v\$parameter where name='shared_pool_size';

     select bytes into actual_used_pool_size from v\$sgastat where pool = 'shared pool' and name       like 'free%';

     select used_space into used_space_SPR from v\$shared_pool_reserved;
                                                                  
     -- Display results
     dbms_output.put_line ('Obj mem:  '||to_char (object_mem) || ' bytes');
     ---dbms_output.put_line ('Shared sql:  '||to_char (shared_sql) || ' bytes');
     ---dbms_output.put_line ('Cursors:  '||to_char (cursor_mem) || ' bytes');
     ----- dbms_output.put_line ('MTS session: '||to_char (mts_mem) || ' bytes');
     dbms_output.put_line ('Free memory: '||to_char (free_mem) || ' bytes ' || '('
     || to_char(round(free_mem/1024/1024,2)) || 'MB)');
     dbms_output.put_line ('Shared pool utilization (total):  '||
     to_char(used_pool_size) || ' bytes ' || '(' ||
     to_char(round(used_pool_size/1024/1024,2)) || 'MB)');
     dbms_output.put_line ('Shared pool allocation (actual):  '|| pool_size ||'
     bytes ' || '(' || to_char(round(pool_size/1024/1024,2)) || 'MB)');

     dbms_output.put_line ('Percentage Utilized:  '||to_char
     (round(100 - (used_pool_size/pool_size*100))) || '%');

     dbms_output.put_line ('SHARED_POOL_RESERVED used_space:   '||to_char(round(used_space_SPR)));

     ---  IF THE SHARED POOL IS GREATER THAN 90% UTILIZED
     ---  if round(100 - (used_pool_size/pool_size*100)) > 90
       if round(used_pool_size/pool_size*100) > 90
       then
          v_command := 'alter system flush shared_pool';
   
          dbms_output.put_line(v_command);

          cur := dbms_sql.open_cursor;
          dbms_sql.parse(cur, v_command, dbms_sql.v7);    
          ret := dbms_sql.execute(cur);
          dbms_sql.close_cursor(cur);
       end if;
end;
/

   spool off

   exit
EOF

remove_file $OUTPUT

return $?
}

###-------------------------------------------------------------------------------------
function oltp_shrink_all_rollbacks
{
   USAGE="Usage: oltp_shrink_all_rollbacks arg1  (arg1=NONE)"

#   if test "$#" -lt 1
#   then
#     echo $USAGE
#     return 1
#   fi

   threshold=$1 

   output_var oltp_shrink_all_rollbacks_$ORACLE_SID.out

   sqlplus -s / <<EOF > /dev/null
   whenever sqlerror exit failure
   set heading on feedback off  linesize 120 pagesize 9999

   spool $OUTPUT

---
---  Shrinks all rollback segments to optimal size
---
declare
     cur     Integer;                -- DSQL: Cursor ID
     ret     Integer;                -- DSQL: Return Value

     v_segment        VARCHAR2(10);
     v_command        VARCHAR2(200);

     CURSOR c1 IS
     select name
     from v\$rollname r
     WHERE r.name like 'RB%';

begin

     OPEN c1;

     LOOP
        fetch c1 into v_segment;
        /* Exit loop when there is no more rows to fetch */
        EXIT WHEN c1%NOTFOUND;

        v_command := 'alter rollback segment ' || CHR(34) || v_segment || CHR(34) || ' shrink';
   
        dbms_output.put_line(v_command);

        cur := dbms_sql.open_cursor;
        dbms_sql.parse(cur, v_command, dbms_sql.v7);    
        ret := dbms_sql.execute(cur);
        dbms_sql.close_cursor(cur);

     END LOOP;

     /* CLOSE CURSOR */
     CLOSE c1;
end;
/

   spool off

   exit
EOF

remove_file $OUTPUT

return $?
}

###-------------------------------------------------------------------------------------
function oltp_coalesce_all_tablespaces
{
   USAGE="Usage: oltp_coalesce_all_tablespaces arg1  (arg1=NONE)"

#   if test "$#" -lt 1
#   then
#     echo $USAGE
#     return 1
#   fi

   threshold=$1 

   output_var oltp_coalesce_all_tablespaces_$ORACLE_SID.out

   sqlplus -s / <<EOF > /dev/null
   whenever sqlerror exit failure
   set heading on feedback off  linesize 120 pagesize 9999

   spool $OUTPUT

---
---  Coalesce All Tablespaces
---
declare
     cur                 Integer;      -- DSQL: Cursor ID
     ret                 Integer;      -- DSQL: Return Value
     v_old_fragments     NUMBER;
     v_new_fragments     NUMBER;

     v_tablespace        VARCHAR2(10);
     v_pct_increase      NUMBER;
     v_command           VARCHAR2(200);

     CURSOR c1 IS
          SELECT tablespace_name, pct_increase
          FROM   dba_tablespaces
          ---WHERE  tablespace_name = 'TEMP'
          ORDER BY tablespace_name;
     
begin

     OPEN c1;

     LOOP
        fetch c1 into v_tablespace, v_pct_increase;
        /* Exit loop when there is no more rows to fetch */
        EXIT WHEN c1%NOTFOUND;


        SELECT count(*)
        INTO   v_old_fragments
        FROM   dba_free_space
        WHERE  tablespace_name = v_tablespace;

        -- coalesce the free space

        v_command := 'alter tablespace '||
                     v_tablespace||
                     ' coalesce';     


        cur := dbms_sql.open_cursor;
        dbms_sql.parse(cur, v_command, dbms_sql.v7);    
        ret := dbms_sql.execute(cur);
        dbms_sql.close_cursor(cur);

        SELECT count(*)
        INTO   v_new_fragments
        FROM   dba_free_space
        WHERE  tablespace_name = v_tablespace;

        dbms_output.put_line('Tablespace '||
                             v_tablespace||
                             ' fragments reduced from '||
                             v_old_fragments||' to '||
                             v_new_fragments);

        if v_pct_increase = 0
        then
           dbms_output.put_line('WARNING:   '||
                                v_tablespace||
                                ' pctincrease = '||
                                v_pct_increase);
        end if;                             

     END LOOP;

     /* CLOSE CURSOR */
     CLOSE c1;
end;
/

   spool off

   exit
EOF

remove_file $OUTPUT

return $?
}

###-------------------------------------------------------------------------------------
function oltp_temp_tablespaces_cleanup
{
   USAGE="Usage: oltp_temp_tablespaces_cleanup arg1  (arg1=NONE)"

#   if test "$#" -lt 1
#   then
#     echo $USAGE
#     return 1
#   fi

   threshold=$1 

   output_var oltp_temp_tablespaces_cleanup_$ORACLE_SID.out

   sqlplus -s / <<EOF > /dev/null
   whenever sqlerror exit failure
   set heading on feedback off  linesize 120 pagesize 9999

   spool $OUTPUT

---
---  Force Temp tablespace cleanup by waking SMON.
---
declare
     cur                 Integer;      -- DSQL: Cursor ID
     ret                 Integer;      -- DSQL: Return Value
     v_old_fragments     NUMBER;
     v_new_fragments     NUMBER;

     v_tablespace        VARCHAR2(10);
     v_pct_increase      NUMBER;
     v_command           VARCHAR2(200);

     CURSOR c1 IS
          SELECT tablespace_name, pct_increase
          FROM   dba_tablespaces
          WHERE  tablespace_name like 'TEMP%'
          ORDER BY tablespace_name;
     
BEGIN

     OPEN c1;

     LOOP
        fetch c1 into v_tablespace, v_pct_increase;
        /* Exit loop when there is no more rows to fetch */
        EXIT WHEN c1%NOTFOUND;

        SELECT count(*)
        INTO   v_old_fragments
        FROM   dba_free_space
        WHERE  tablespace_name = v_tablespace;

        v_command := 'alter tablespace '||
                     v_tablespace||
                     ' default storage(pctincrease 1)';     

        cur := dbms_sql.open_cursor;
        dbms_sql.parse(cur, v_command, dbms_sql.v7);    
        ret := dbms_sql.execute(cur);
        dbms_sql.close_cursor(cur);

        v_command := 'alter tablespace '||
                     v_tablespace||
                     ' coalesce';     

        cur := dbms_sql.open_cursor;
        dbms_sql.parse(cur, v_command, dbms_sql.v7);    
        ret := dbms_sql.execute(cur);
        dbms_sql.close_cursor(cur);

        SELECT count(*)
        INTO   v_new_fragments
        FROM   dba_free_space
        WHERE  tablespace_name = v_tablespace;

        dbms_output.put_line('Tablespace '||
                             v_tablespace||
                             ' fragments reduced from '||
                             v_old_fragments||' to '||
                             v_new_fragments);

        if v_pct_increase = 0
        then
           dbms_output.put_line('WARNING:   '||
                                v_tablespace||
                                ' pctincrease = '||
                                v_pct_increase);
        end if;                             

     END LOOP;

     /* CLOSE CURSOR */
     CLOSE c1;
end;
/

   spool off

   exit
EOF

remove_file $OUTPUT

return $?
}

###-------------------------------------------------------------------------------------
function oltp_kill_crystal_sessions
{
   USAGE="Usage: oltp_kill_crystal_sessions arg1  (arg1=NONE)"

#   if test "$#" -lt 1
#   then
#     echo $USAGE
#     return 1
#   fi

   threshold=$1 

   output_var oltp_kill_crystal_sessions_$ORACLE_SID.out

   sqlplus -s / <<EOF > /dev/null
   whenever sqlerror exit failure
   set heading on feedback off  linesize 120 pagesize 9999

   spool $OUTPUT

---
---  Kills any Crystal sessions  sessions running using > 1GB of system resources.
---
declare
     cur     Integer;                -- DSQL: Cursor ID
     ret     Integer;                -- DSQL: Return Value
     v_sid            NUMBER;
     v_serial#        NUMBER;
     v_command        VARCHAR2(200);

     CURSOR c1 IS
     SELECT s.sid, s.serial#
     FROM V\$SESSION S,
          V\$SESSTAT C
     WHERE S.SID=C.SID
     and s.status not in ('KILLED','SNIPED')
     and substr(s.username,1,1) in ('A','N;')
     and substr(s.username,2,1) in ('0','1','2','3','4','5','6','7','8','9')
     AND C.STATISTIC# = 12
     and (C.VALUE > 1000000000
            or c.value < 0);

begin

     OPEN c1;

     LOOP
        fetch c1 into v_sid, v_serial#;
        /* Exit loop when there is no more rows to fetch */
        EXIT WHEN c1%NOTFOUND;

        v_command := 'alter system kill session ' || CHR(39) || v_sid || ', ' || v_serial# || CHR(39);
   
        dbms_output.put_line(v_command);

        cur := dbms_sql.open_cursor;
        dbms_sql.parse(cur, v_command, dbms_sql.v7);    
        ret := dbms_sql.execute(cur);
        dbms_sql.close_cursor(cur);

     END LOOP;

     /* CLOSE CURSOR */
     CLOSE c1;
end;
/

   spool off

   exit
EOF

remove_file $OUTPUT

return $?
}

###-------------------------------------------------------------------------------------
function oltp_kill_persistent_connections
{
   USAGE="Usage: oltp_kill_persistent_connections arg1  (arg1=NONE)"

#   if test "$#" -lt 1
#   then
#     echo $USAGE
#     return 1
#   fi

   threshold=$1 

   output_var oltp_kill_persistent_connections_$ORACLE_SID.out

   sqlplus -s / <<EOF > /dev/null
   whenever sqlerror exit failure
   set heading on feedback off  linesize 120 pagesize 9999

   spool $OUTPUT

---
---  Kills any sessions connected over a threshold.
---
declare
     cur     Integer;                -- DSQL: Cursor ID
     ret     Integer;                -- DSQL: Return Value
     v_sid            NUMBER;
     v_serial#        NUMBER;
     v_command        VARCHAR2(200);

     CURSOR c1 IS
     SELECT s.sid, s.serial#
     FROM V\$SESSION S,
          V\$SESSTAT C
     WHERE S.SID=C.SID
     and s.status not in ('KILLED','SNIPED')
     and substr(s.username,1,1) in ('A','N;')
     and substr(s.username,2,1) in ('0','1','2','3','4','5','6','7','8','9')
     and (sysdate - logon_time >= (60 * 10 / 1440))

     ---and osuser not like '%ora%'
     and username not in ('BACKGROUND')
     and UPPER(machine) not like ('S%');

begin

     OPEN c1;

     LOOP
        fetch c1 into v_sid, v_serial#;
        /* Exit loop when there is no more rows to fetch */
        EXIT WHEN c1%NOTFOUND;

        v_command := 'alter system kill session ' || CHR(39) || v_sid || ', ' || v_serial# || CHR(39);
   
        dbms_output.put_line(v_command);

        cur := dbms_sql.open_cursor;
        dbms_sql.parse(cur, v_command, dbms_sql.v7);    
        ret := dbms_sql.execute(cur);
        dbms_sql.close_cursor(cur);

     END LOOP;

     /* CLOSE CURSOR */
     CLOSE c1;
end;
/

   spool off

   exit
EOF

remove_file $OUTPUT

return $?
}

############################################################
####  USEFUL FUNCTIONS
############################################################

###-------------------------------------------------------------------------------------
function estimate_table_size
{
   USAGE="Usage: estimate_table_size arg1 arg2 arg3 arg4 (arg1=owner) (arg2=table name) (arg3=number of rows) (arg4=row length) "

   if test "$#" -lt 4
   then
      echo $USAGE
      return 1
   fi

   typeset -u table_owner_p=$1 
   typeset -u table_name_p=$2
   typeset -i table_rows_p=$3
   typeset -i table_row_length_p=$4

   output_var estimate_table_size_$ORACLE_SID.out

   sqlplus -s / <<EOF > /dev/null
   whenever sqlerror exit failure
   set heading on feedback off  linesize 80 pagesize 9999
   set serveroutput on

   spool $OUTPUT

---
---  Estimates table size for a specified table.
---

declare

  table_owner_p VARCHAR2(10) := '$table_owner_p';
  table_name_p VARCHAR2(30) := '$table_name_p';
  table_rows_p INTEGER := $table_rows_p;
  table_row_length_p INTEGER := $table_row_length_p;

  DEBUG BOOLEAN := FALSE;  -- set TRUE if you want to know what the procedure is doing
  avg_row_length_v NUMBER(18,2);   -- avg row length from table's rows
  calc_loop_v NUMBER :=3;          -- cntr used in calc processing
  col_tmp_v NUMBER := 0;           -- size of the column
  col_1_v NUMBER   := 0;           -- columns with size < 250
  col_250_v NUMBER := 0;           -- columns with size >= 250
  colname_v sys.dba_tab_columns.column_name%TYPE; -- column_name
  col_type_v sys.dba_tab_columns.data_type%TYPE;  -- column type
  h INTEGER := 0;                  -- size of fixed block header
  x INTEGER := 0;                  -- rows per block
--  y INTEGER := 0;                -- not used
--  z NUMBER  := 0;                -- not used
  cursor_v INTEGER;                -- cursor variable
  block_size_v INTEGER := 0;       -- block size
  initrans_v INTEGER := 1;         -- initrans of the table
  pct_free_v NUMBER(3,2) := 0.10;  -- pct_free of the table
  all_col_length_v NUMBER :=0;     -- total of max column storage
  ignore_v INTEGER;                -- for cursor
  row_size_v NUMBER(18,2);      -- size of a row
  table_size_v NUMBER(20,2);    -- size of the table
  vsizestmt_v VARCHAR2(8000);   -- sql-clause
  grade_v VARCHAR2(10) := 'K';  -- grade (bytes,Kilobytes,Megabytes)
--  err_v VARCHAR2(200);           -- error number  (not used)
--  num_v INTEGER;                 -- error number  (not used)

  --  Cursor to read the table's structure in the dictionary
  --  and get the maximum length stored in the db for its type
  CURSOR columns_cur IS
    SELECT column_name,
           data_type,
    decode(data_type,'NUMBER',floor(nvl(data_precision,38)/2)+1+1+1,data_length)
        FROM sys.dba_tab_columns
        WHERE table_name = table_name_p
          AND owner      = table_owner_p
              order by column_id;
begin
  dbms_output.enable(1000000);
  
  -- PCTFREE ---
  SELECT (pct_free/100) into pct_free_v
    FROM sys.dba_tables
   WHERE table_name = table_name_p
     AND owner      = table_owner_p;

  -- INITRANS ---
  SELECT ini_trans   into initrans_v
    FROM sys.dba_tables
   WHERE table_name = table_name_p
    AND owner      = table_owner_p;

  -- BLOCK_SIZE
  SELECT value into block_size_v
    FROM sys.v_\$parameter
   WHERE name='db_block_size';

  -- sql-clause begins
  -- this clause will calculate the size of of each row in bytes
  vsizestmt_v := 'SELECT AVG(';
  OPEN columns_cur;
     LOOP
         FETCH columns_cur INTO colname_v,col_type_v,col_tmp_v;
               EXIT WHEN columns_cur%NOTFOUND;
               IF col_tmp_v >= 250 THEN
                  col_250_v := col_250_v + 1;
               ELSE
                  col_1_v := col_1_v + 1;
               END IF;

         all_col_length_v := all_col_length_v + col_tmp_v;

         IF DEBUG THEN
            dbms_output.put_line(colname_v||'  c1 '||col_1_v||'  c2 '||col_250_v|| '  max length in db '||col_tmp_v);
         --   dbms_output.new_line;
         END IF;


         IF col_type_v != 'LONG' then
            vsizestmt_v := vsizestmt_v||'NVL(VSIZE('||colname_v||'),0) +';
         END IF;

     END LOOP;
  CLOSE columns_cur;

  -- get rid of the last '+'
  vsizestmt_v := substr(vsizestmt_v,1,(length(vsizestmt_v)-1));
  -- end of the sql-clause
  vsizestmt_v := vsizestmt_v||') AVERAGE_ROW_SIZE FROM '||table_owner_p||'.'||table_name_p;


  IF DEBUG THEN
     dbms_output.put_line('	');  -- this is a tab
     dbms_output.put('vsizestmt '||substr(vsizestmt_v,1,235));
     dbms_output.put_line('	');  -- this is a tab
  END IF;   

  -- execute the sql-clause
  cursor_v := DBMS_SQL.OPEN_CURSOR;
  DBMS_SQL.PARSE(cursor_v,vsizestmt_v,1);
  DBMS_SQL.DEFINE_COLUMN(cursor_v,1,avg_row_length_v);
  ignore_v := DBMS_SQL.EXECUTE(cursor_v);
  IF DBMS_SQL.FETCH_ROWS(cursor_v) >0 THEN
     DBMS_SQL.COLUMN_VALUE(cursor_v,1,avg_row_length_v);
  END IF;
  DBMS_SQL.CLOSE_CURSOR(cursor_v);

-- Do 3 different calculations
--    1 using avg row length from actual data in table
--    1 using the maxinum row length based on the column descriptions
--    1 using the row length entered
WHILE calc_loop_v > 0
  LOOP
      IF calc_loop_v = 3 THEN
         row_size_v := avg_row_length_v;
      ELSE
         IF calc_loop_v = 2 THEN
            row_size_v := all_col_length_v;
         ELSE
            row_size_v := table_row_length_p;
         END IF;
      END IF;

  -- row size (actually bytes per row;  fraction up)
  row_size_v := ceil(row_size_v) + 3 + col_1_v + (3 * col_250_v);

  -- fixed block header size
  h := 57 + (23 * initrans_v);

  -- rows per block (x) (no rounding)
  x := floor(((block_size_v - h) - ((block_size_v - h) * pct_free_v) - 4) / (row_size_v + 2));


  IF DEBUG THEN
    dbms_output.put('rows per block:'||x||' row size:'||row_size_v||' hdr:'||h);
    dbms_output.put_line('	');  -- this is a tab
  END IF;


  -- calculate the size of the table
  table_size_v := (table_rows_p / x ) * block_size_v;

  IF DEBUG THEN
     dbms_output.put('Table Size in Bytes: '||table_size_v);
     dbms_output.put_line('	');  -- this is a tab
  END IF;

  -- if table is empty
  IF table_size_v is null then
     grade_v := '0 rows?';
     table_size_v := -1;
  ELSE
     -- choose the grade
     IF table_size_v >  1048576 THEN
        table_size_v := table_size_v / 1048576;
        grade_v := 'MB';
     ELSE
        table_size_v := table_size_v/1024;
        grade_v := 'KB';
     END IF;
  END IF;

  -- Show the result
--  dbms_output.put_line('	');  -- this is a tab
  dbms_output.put_line('. ' ); 
  dbms_output.put_line('.               TABLE SIZE FOR NUMBER OF ROWS');
  IF calc_loop_v = 3 THEN
    dbms_output.put_line('.      (avg row length calculated from table data: '||
                         avg_row_length_v||')');
    dbms_output.put_line('.      (avg row size calculated from table_data: '||
                         row_size_v||')');
  ELSE
    IF calc_loop_v = 2 THEN
      dbms_output.put_line('.    (max row length calculated from column types: '||
                         all_col_length_v||')');
      dbms_output.put_line('.     (max row size calculated from column types: '||
                         row_size_v||')');
    ELSE
      dbms_output.put_line('.     (row length entered: '||
                         table_row_length_p||')');
      dbms_output.put_line('.     (row size calculated from entered row length: '||
                         row_size_v||')');
    END IF;
  END IF;
  dbms_output.put_line(rpad(table_name_p,30)||' '||
                  lpad(table_rows_p,12)||'  '||
                  lpad(to_char(table_size_v,'9999990D9999'),13)||' '||grade_v);
--  dbms_output.put_line('	');  -- this is a tab
  dbms_output.put_line('. ' ); 

  calc_loop_v := calc_loop_v - 1;

  END LOOP;

----------------- exceptions ----------------------------------------------
---EXCEPTION
---WHEN OTHERS THEN
---  err_v := SQLERRM;
---  num_v := SQLCODE;
---  dbms_output.put_line(num_v);
---  dbms_output.put_line(err_v);
END; -- end of the procedure estimate_table_size
/

   spool off

   exit
EOF

cat $OUTPUT
remove_file $OUTPUT

return $?
}

############################################################
####  ADMINISTRATIVE FUNCTIONS
############################################################

###-------------------------------------------------------------------------------------
function compile_invalid_objects_all
{
   USAGE="Usage: compile_invalid_objects_all arg1  (arg1=mailing list)"

   if test "$#" -lt 1
   then
     echo $USAGE
     return 1
   fi

   mailist=$1

   output_var compile_invalid_objects_$mailist.out

   sqlplus -s / <<EOF > /dev/null
   whenever sqlerror exit failure
   set heading on feedback off  pagesize 9999

   spool $OUTPUT

SET FEEDBACK OFF
SET TERMOUT OFF
SET PAGESIZE 0

SPOOL $SCRIPTS/dynamic/compobj.sql

SELECT '@$SCRIPTS/setupenv.sql $ORACLE_SID' FROM DUAL;
SELECT 'SET FEEDBACK ON'  FROM DUAL;
SELECT 'SPOOL $OUTPUT' FROM DUAL;

SELECT 'PROMPT Compile VIEW ' || OWNER || '.' || OBJECT_NAME || ' ...' || CHR(10) ||
       'ALTER VIEW ' || OWNER || '.' || OBJECT_NAME || ' COMPILE;' || CHR(10) || 'SHOW ERRORS;' || CHR(10) || 'PROMPT;'
  FROM DBA_OBJECTS WHERE STATUS <> 'VALID'   AND OBJECT_TYPE =  'VIEW'
 ORDER BY OBJECT_NAME;

SELECT 'PROMPT Compile TRIGGER ' || OWNER || '.' || OBJECT_NAME || ' ...' || CHR(10) ||
       'ALTER TRIGGER ' || OWNER || '.' || OBJECT_NAME || ' COMPILE;' || CHR(10) || 'SHOW ERRORS;' || CHR(10) || 'PROMPT;'
  FROM DBA_OBJECTS WHERE STATUS <> 'VALID'   AND OBJECT_TYPE =  'TRIGGER'
 ORDER BY OBJECT_NAME;

SELECT 'PROMPT Compile PROCEDURE ' || OWNER || '.' || OBJECT_NAME || ' ...' || CHR(10) ||
       'ALTER PROCEDURE ' || OWNER || '.' || OBJECT_NAME || ' COMPILE;' || CHR(10) || 'SHOW ERRORS;' || CHR(10) || 'PROMPT;'
  FROM DBA_OBJECTS WHERE STATUS <> 'VALID'   AND OBJECT_TYPE =  'PROCEDURE'
 ORDER BY OBJECT_NAME;

SELECT 'PROMPT Compile FUNCTION ' || OWNER || '.' || OBJECT_NAME || ' ...' || CHR(10) ||
       'ALTER FUNCTION ' || OWNER || '.' || OBJECT_NAME || ' COMPILE;' || CHR(10) || 'SHOW ERRORS;' || CHR(10) || 'PROMPT;'
  FROM DBA_OBJECTS WHERE STATUS <> 'VALID'   AND OBJECT_TYPE =  'FUNCTION'
 ORDER BY OBJECT_NAME;

SELECT 'PROMPT Compile PACKAGE ' || OWNER || '.' || OBJECT_NAME || ' ...' || CHR(10) ||
       'ALTER PACKAGE ' || OWNER || '.' || OBJECT_NAME || ' COMPILE;' || CHR(10) || 'SHOW ERRORS;' || CHR(10) || 'PROMPT;'
  FROM DBA_OBJECTS WHERE STATUS <> 'VALID'   AND OBJECT_TYPE = 'PACKAGE'
 ORDER BY OBJECT_NAME;

SELECT 'PROMPT Compile PACKAGE BODY ' || OWNER || '.' || OBJECT_NAME || ' ...' || CHR(10) ||
       'ALTER PACKAGE ' || OWNER || '.' || OBJECT_NAME || ' COMPILE BODY;' || CHR(10) || 'SHOW ERRORS;' || CHR(10) || 'PROMPT;'
  FROM DBA_OBJECTS WHERE STATUS <> 'VALID'   AND OBJECT_TYPE = 'PACKAGE BODY'
 ORDER BY OBJECT_NAME;
SELECT 'SPOOL OFF' FROM DUAL;

SPOOL OFF

START $SCRIPTS/dynamic/compobj.sql

SET TERMOUT ON
SET ECHO OFF
SET FEEDBACK OFF

SELECT '>>> Invalid objects '  FROM DUAL;
SELECT OBJECT_TYPE || ': ' || OWNER || '.' || OBJECT_NAME  FROM DBA_OBJECTS
 WHERE STATUS <> 'VALID' ORDER BY OBJECT_TYPE, OWNER, OBJECT_NAME;
SELECT '>>> Total: ' || COUNT(*)  FROM DBA_OBJECTS WHERE STATUS <> 'VALID';

START $SCRIPTS/dynamic/compobj.sql

---   spool off

   exit
EOF

    MailIt "Compile Invalid Objects All $ORACLE_SID" $OUTPUT $mailist email

return $?
} 

###-------------------------------------------------------------------------------------
function compile_invalid_objects
{
   USAGE="Usage: compile_invalid_objects arg1 (arg1=object type) arg2  (arg2=sort indicator)"

   if test "$#" -lt 1
   then
     echo $USAGE
     return 1
   fi

   typeset -u objtype=$1
   sortind=$2

   if [ $objtype == "FUNCTION" -o $objtype == "PACKAGE" -o $objtype == "PACKAGEBODY" -o $objtype == "PROCEDURE" -o $objtype == "TRIGGER" -o $objtype == "TYPE" -o $objtype == "VIEW" ]
   then
        echo "Compiling Invalid $objtype Objects..."
   else
        echo "Valid object types are: FUNCTION, PACKAGE, PACKAGEBODY, PROCEDURE, TRIGGER, TYPE or VIEW"
        return 1
   fi

   output_var compile_invalid_$objtype_$mailist.out

   export DYNAMIC=$SCRIPTS/dynamic/compile_$objtype.sql

   # Check if xtrace debugging should be started
   typeset -i DebugLevel
   if [[ $DebugLevel == 9 ]]
   then
      set -o xtrace
   else
      set +o xtrace
   fi 

   if [ $objtype == "PACKAGEBODY" ]
   then
   sqlplus -s / <<EOF > /dev/null
   whenever sqlerror exit failure
   set heading off feedback off echo off  pagesize 9999

         spool $DYNAMIC
         select 'ALTER PACKAGE '||owner||'.'||object_name||' COMPILE BODY;'
         from dba_objects
         where object_type = 'PACKAGE BODY'
         and status = 'INVALID'
          order by 1 $sortind;
          spool off

          spool $OUTPUT

          prompt
          prompt ===================================
          prompt ===  Compile Invalid $objtype         ===
          prompt ===================================
         prompt

        set feedback off echo off
        @$DYNAMIC

        spool off
       exit
EOF


   else

   sqlplus -s / <<EOF > /dev/null
   whenever sqlerror exit failure
   set heading off feedback off feedback off  pagesize 9999

        spool $DYNAMIC
        select 'ALTER $objtype '||owner||'.'||object_name||' COMPILE;'
        from dba_objects
        where object_type = '$objtype'
        and status = 'INVALID'
        order by 1 $sortind;
        spool off

        spool $OUTPUT

        prompt
        prompt ===================================
        prompt ===  Compile Invalid $objtype         ===
        prompt ===================================
        prompt

       set feedback off echo off
       @$DYNAMIC

       spool off
       exit
EOF

   fi

    rm $DYNAMIC

return $?
} 

###-------------------------------------------------------------------------------------
function comp_all
{
   USAGE="Usage: comp_all (no aguments)"

   compile_invalid_objects trigger
   compile_invalid_objects view
   compile_invalid_objects type
   compile_invalid_objects function
   compile_invalid_objects procedure
   compile_invalid_objects packagebody
   compile_invalid_objects package

return $?
} 



###-------------------------------------------------------------------------------------
function analyze_schema
{
   USAGE="Usage: analyze_schema (none)"

#   if test "$#" -lt 1
#   then
#     echo $USAGE
#     return 1
#   fi

   ANALYZETHESE=$SCRIPTS/analyze/analyze_list.dat
   ANALYZEDBSQL=$SCRIPTS/analyze/analyze_$ORACLE_SID.sql
   ANALYZEDBOUT=$SCRIPTS/analyze/analyze_$ORACLE_SID.out

   echo "set timing on" > $ANALYZEDBSQL

   cat $ANALYZETHESE | while read LINE
   do
       ANALYZE_SID=`echo $LINE | awk -F: '{print $1}' -`
       if [ "$ORACLE_SID" = "$ANALYZE_SID" ] ; then
          SCHEMANAME=`echo $LINE | awk -F: '{print $2}' -`
          METHOD=`echo $LINE | awk -F: '{print $3}' -`
          SAMPLE=`echo $LINE | awk -F: '{print $4}' -`

          if [ "$METHOD" = "estimate" ] ; then
             echo "PROMPT" >> $ANALYZEDBSQL
             echo "PROMPT analyzing schema $SCHEMANAME..." >> $ANALYZEDBSQL
             echo "execute dbms_utility.analyze_schema ( '$SCHEMANAME','$METHOD',$SAMPLE );" >> $ANALYZEDBSQL
          else
             echo "PROMPT" >> $ANALYZEDBSQL
             echo "PROMPT analyzing schema $SCHEMANAME..." >> $ANALYZEDBSQL
             echo "execute dbms_utility.analyze_schema ( '$SCHEMANAME','$METHOD' );" >> $ANALYZEDBSQL
          fi
       fi

   done 

   echo "exit;" >> $ANALYZEDBSQL


   sqlplus -s / <<EOF > /dev/null
   whenever sqlerror exit failure

spool $ANALYZEDBOUT 

start $ANALYZEDBSQL

spool off


/* Clear before exiting this script */

/* EXIT Sqlplus */

exit

EOF


return $?
} 


###-------------------------------------------------------------------------------------
function hotbackupbatch
{
   USAGE="Usage: hotbackupbatch arg1 arg2 (arg1= Batchsize, arg2= Retention Days)"

   if test "$#" -lt 2
   then
     echo $USAGE
     return 1
   fi

   typeset -i BATCHSIZE=$1
   RETPER=$2 

### Check if database instance is Up
   GetProcessStatus ora_pmon_${ORACLE_SID}
   if test "$?" -ne 0
   then
      echo "ORACLE: System PMON for ORACLE_SID=${ORACLE_SID} is not running."
      return 1
   fi

   #------------------------------------------------------------#
   #--  remove backup directories based on RETPER provided    --#
   #------------------------------------------------------------#
   if [[ $RETPER == "NONE" ]]
   then
      rm -r ${INSTANCE_OUTPUTS}/backups/HOTBKP*
   else
      find ${INSTANCE_OUTPUTS}/backups -name "HOTBKP*" -type d -mtime ${RETPER} -exec rm -r {} \; 2>>/dev/null
   fi 

   #------------------------------------------------------------#
   #--  Create new HOTBKP directory                           --#
   #------------------------------------------------------------#
   OUTPUT_TO=$INSTANCE_OUTPUTS/backups/HOTBKP$DATETIME
   mkdir -p $OUTPUT_TO

   sqlplus -s / <<EOF > /dev/null
   whenever sqlerror exit failure
   set heading on feedback off  pagesize 9999

rem
rem
rem
set linesize 255 pagesize 0 heading off verify off echo off
set serveroutput on size 700000

/* This section creates the Backup_batch.ksh files & Restore_batch.ksh */
/*  */
spool $OUTPUT_TO/run_cr_hot.sql

declare
   s_path VARCHAR(60) := '$OUTPUT_TO/';
   s_batchsize NUMBER := $BATCHSIZE;
   line VARCHAR2(1024);
   v_filename	VARCHAR2(70) := ' ';
   v_tablespace VARCHAR2(30) := ' ';
   hold_tablespace VARCHAR2(30) := ' ';
   nCntr  NUMBER :=0;
   nBatch NUMBER :=1;
   v_backup_name_prefix VARCHAR2(15) := 'hbackup_batch';
   v_restore_name_prefix VARCHAR2(15) := 'hrestore_batch';

---  Tablespace Information
CURSOR c1 IS
select substr(file_name,1,70),tablespace_name
from sys.dba_data_files
order by tablespace_name,substr(file_name,1,70);


BEGIN

     line := 'spool ';
     line := line || s_path;
     line := line ||  v_backup_name_prefix;
     line := line || nBatch;
     line := line || '.sql';
     DBMS_OUTPUT.PUT_LINE(rtrim(line));

     line := 'select  ';
     line := line || CHR(39);
     line := line || 'define DBInstance = \$ORACLE_SID';
     line := line || CHR(39);
     line := line || ' from dual;';
     DBMS_OUTPUT.PUT_LINE(rtrim(line));

     line := 'select  ';
     line := line || CHR(39);
     line := line || '@\$SCRIPTS/setupenv.sql \$ORACLE_SID';
     line := line || CHR(39);
     line := line || ' from dual;';
     DBMS_OUTPUT.PUT_LINE(rtrim(line));

     line := 'select  ';
     line := line || CHR(39);
     line := line || 'set linesize 255 heading off';
     line := line || CHR(39);
     line := line || ' from dual;';
     DBMS_OUTPUT.PUT_LINE(rtrim(line));

     line := 'select  ';
     line := line || CHR(39);
     line := line || 'spool ';
     line := line || s_path;
     line := line || v_backup_name_prefix;
     line := line || nBatch;
     line := line || '.lst';
     line := line || CHR(39);
     line := line || ' from dual;';
     DBMS_OUTPUT.PUT_LINE(rtrim(line));

--- Create backup file statements (Compress)
     OPEN c1;

     fetch c1 into v_filename,v_tablespace;

     LOOP

---     Write begin tablespace backup
        IF v_tablespace != hold_tablespace THEN

           hold_tablespace := v_tablespace;

           line := 'select  ';
           line := line || CHR(39);
           line := line || 'prompt ';
           line := line || 'Begin Backup of ';
           line := line ||  v_tablespace;
           line := line || CHR(39);
           line := line || ' from dual;';
           DBMS_OUTPUT.PUT_LINE(rtrim(line));

           line := 'select  ';
           line := line || CHR(39);
           line := line || 'alter tablespace ';
           line := line || v_tablespace;
           line := line || ' begin backup ;';
           line := line || CHR(39);
           line := line || ' from dual;';
           DBMS_OUTPUT.PUT_LINE(rtrim(line));

        END IF;


--- code suggested by UNIX admin
--- compress < $v_filename > $v_filename.Z && print "$v_filename" >> compress.log || print "$v_filename FAILED, status=$?" >> compress.log

---     Build backup statement for datafile

        line := 'select  ';
        line := line || CHR(39);
        line := line || '!gzip -c ';
        line := line || v_filename;
        line := line || ' > ';
        line := line || substr( replace(replace(v_filename,'/','.'),'.oradata'),2,99);
        line := line || '.gz';
        line := line || ' 2>> ';
        line := line || 'compress.log';
        line := line || CHR(39);
        line := line || ' from dual;';
        DBMS_OUTPUT.PUT_LINE(rtrim(line));

---        line := 'select  ';
---        line := rtrim(line) || CHR(39);
---        line := rtrim(line) || '!compress < ';
---        line := rtrim(line) || v_filename;
---        line := rtrim(line) || ' > ';
----        line := rtrim(line) || s_path;
---        line := rtrim(line) || substr( replace(replace(v_filename,'/','.'),'.oradata'),2,99);
---        line := rtrim(line) || '.Z ';
---        line := rtrim(line) || ' && print ';
---        line := rtrim(line) || CHR(34);
---        line := rtrim(line) || v_filename;        
---        line := rtrim(line) || CHR(34);
---        line := rtrim(line) || ' >> ';
----        line := rtrim(line) || s_path;
---        line := rtrim(line) || ' compress.log';
---        line := rtrim(line) || ' || print ';
---        line := rtrim(line) || CHR(34);
---        line := rtrim(line) || v_filename;
---        line := rtrim(line) || ' FAILED, status=$?';
---        line := rtrim(line) || CHR(34);
---        line := rtrim(line) || ' >> ';
----        line := rtrim(line) || s_path;
---        line := rtrim(line) || ' compress.log ';
---        line := rtrim(line) || CHR(39);
---        line := rtrim(line) || ' from dual;';
---        DBMS_OUTPUT.PUT_LINE(rtrim(line));

---     Build ls -l of backup file to log
        line := 'select  ';
        line := line || CHR(39);
        line := line || '!ls -l ';
        line := line || substr( replace(replace(v_filename,'/','.'),'.oradata'),2,99);
        line := line || '.gz';
        line := line || ' >> ';
        line := line || 'compress.log';
        line := line || ' 2>> ';
        line := line || 'compress.log';
        line := line || CHR(39);
        line := line || ' from dual;';
        DBMS_OUTPUT.PUT_LINE(rtrim(line));

        /* Increment datafile procecessed counter */
        nCntr := nCntr + 1;

        fetch c1 into v_filename,v_tablespace;
        /* Exit loop when there is no more rows to fetch */
        EXIT WHEN c1%NOTFOUND;

        IF v_tablespace != hold_tablespace THEN
           line := 'select  ';
           line := line || CHR(39);
           line := line || 'alter tablespace ';
           line := line || hold_tablespace;
           line := line || ' end backup ;';
           line := line || CHR(39);
           line := line || ' from dual;';
           DBMS_OUTPUT.PUT_LINE(rtrim(line));

           line := 'select  ';
           line := line || CHR(39);
           line := line || 'prompt ';
           line := line || 'End Backup of ';
           line := line ||  hold_tablespace;
           line := line || CHR(39);
           line := line || ' from dual;';
           DBMS_OUTPUT.PUT_LINE(rtrim(line));

           IF nCntr >= s_batchsize THEN 
              line := 'select  ';
              line := line || CHR(39);
              line := line || 'spool off';
              line := line || CHR(39);
              line := line || ' from dual;';
              DBMS_OUTPUT.PUT_LINE(rtrim(line));

              line := 'select  ';
              line := line || CHR(39);
              line := line || 'quit';
              line := line || CHR(39);
              line := line || ' from dual;';
              DBMS_OUTPUT.PUT_LINE(rtrim(line));

              line := 'spool off';
              DBMS_OUTPUT.PUT_LINE(rtrim(line));

              nCntr :=0;
              nBatch := nBatch + 1;
              line := 'spool ';
              line := line || s_path;
              line := line || v_backup_name_prefix;
              line := line || nBatch;
              line := line || '.sql';
              DBMS_OUTPUT.PUT_LINE(rtrim(line));

              line := 'select  ';
              line := line || CHR(39);
              line := line || 'define DBInstance = \$ORACLE_SID';
              line := line || CHR(39);
              line := line || ' from dual;';
              DBMS_OUTPUT.PUT_LINE(rtrim(line));

              line := 'select  ';
              line := line || CHR(39);
              line := line || '@\$SCRIPTS/setupenv.sql \$ORACLE_SID ';
              line := line || CHR(39);
              line := line || ' from dual;';
              DBMS_OUTPUT.PUT_LINE(rtrim(line));

              line := 'select  ';
              line := line || CHR(39);
              line := line || 'set linesize 255 heading off';
              line := line || CHR(39);
              line := line || ' from dual;';
              DBMS_OUTPUT.PUT_LINE(rtrim(line));

              line := 'select  ';
              line := line || CHR(39);
              line := line || 'spool ';
              line := line || s_path;
              line := line || v_backup_name_prefix;
              line := line || nBatch;
              line := line || '.lst';
              line := line || CHR(39);
              line := line || ' from dual;';
              DBMS_OUTPUT.PUT_LINE(rtrim(line));
           END IF;
        END IF;


     END LOOP;

     /* CLOSE CURSOR */
     CLOSE c1;

     line := 'select  ';
     line := line || CHR(39);
     line := line || 'alter tablespace ';
     line := line || hold_tablespace;
     line := line || ' end backup ;';
     line := line || CHR(39);
     line := line || ' from dual;';
     DBMS_OUTPUT.PUT_LINE(rtrim(line));

     line := 'select  ';
     line := line || CHR(39);
     line := line || 'prompt ';
     line := line || 'End Backup of ';
     line := line ||  hold_tablespace;
     line := line || CHR(39);
     line := line || ' from dual;';
     DBMS_OUTPUT.PUT_LINE(rtrim(line));

     line := 'select  ';
     line := line || CHR(39);
     line := line || 'spool off';
     line := line || CHR(39);
     line := line || ' from dual;';
     DBMS_OUTPUT.PUT_LINE(rtrim(line));

     /* QUIT the sqlplus session */
     line := 'select  ';
     line := line || CHR(39);
     line := line || 'quit';
     line := line || CHR(39);
     line := line || ' from dual;';
     DBMS_OUTPUT.PUT_LINE(rtrim(line));

     line := 'spool off';
     DBMS_OUTPUT.PUT_LINE(rtrim(line));

     /*------------------------------------------------------------------------------------*/
     /* Create finale SQL file to backup controlfile and list logfile info. */
     nCntr :=0;
     nBatch := nBatch + 1;
     line := 'spool ';
     line := line || s_path;
     line := line || 'finale_batch';
     line := line || '.sql';
     DBMS_OUTPUT.PUT_LINE(rtrim(line));

     line := 'select  ';
     line := line || CHR(39);
     line := line || 'spool ';
     line := line || s_path;
     line := line || v_backup_name_prefix;
     line := line || nBatch;
     line := line || '.lst';
     line := line || CHR(39);
     line := line || ' from dual;';
     DBMS_OUTPUT.PUT_LINE(rtrim(line));

     line := 'select  ';
     line := line || CHR(39);
     line := line || 'set linesize 255 pagesize 500';
     line := line || CHR(39);
     line := line || ' from dual;';
     DBMS_OUTPUT.PUT_LINE(rtrim(line));

     line := 'select  ';
     line := line || CHR(39);
     line := line || 'prompt Start Backup of controlfile ';
     line := line || CHR(39);
     line := line || ' from dual;';
     DBMS_OUTPUT.PUT_LINE(rtrim(line));


     /* Perform logfile switch */ 
     line := 'prompt  alter system switch logfile';
     DBMS_OUTPUT.PUT_LINE(rtrim(line));

     line := 'select  ';
     line := line || CHR(39);
     line := line || ';';
     line := line || CHR(39);
     line := line || ' from dual;';
     DBMS_OUTPUT.PUT_LINE(rtrim(line));

     /* Backup controlfile */ 
     line := 'prompt  ';
     line := line || 'alter database backup controlfile to ';
     line := line || CHR(39);
     line := line || s_path;
     line := line || 'backup.ctl_';
     line := line || to_char(sysdate,'YYYYMMDD.HH24MISS');
     line := line || CHR(39);
     DBMS_OUTPUT.PUT_LINE(rtrim(line));

     line := 'select  ';
     line := line || CHR(39);
     line := line || ';';
     line := line || CHR(39);
     line := line || ' from dual;';
     DBMS_OUTPUT.PUT_LINE(rtrim(line));

     line := 'select  ';
     line := line || CHR(39);
     line := line || 'prompt End Backup of controlfile ';
     line := line || CHR(39);
     line := line || ' from dual;';
     DBMS_OUTPUT.PUT_LINE(rtrim(line));

     line := 'select  ';
     line := line || CHR(39);
     line := line || 'select substr(member,1,70) MEMBER from v\$logfile;';
     line := line || CHR(39);
     line := line || ' from dual;';
     DBMS_OUTPUT.PUT_LINE(rtrim(line));

     line := 'select  ';
     line := line || CHR(39);
     line := line || 'select substr(d.name,1,60) DATAFILE, b.status, b.time, b.change#  from v\$backup b, v\$datafile d where b.file# = d.file#;';
     line := line || CHR(39);
     line := line || ' from dual;';
     DBMS_OUTPUT.PUT_LINE(rtrim(line));

     line := 'select  ';
     line := line || CHR(39);
     line := line || 'select count(*) FILES_TO_BACK_UP from dba_data_files;';
     line := line || CHR(39);
     line := line || ' from dual;';
     DBMS_OUTPUT.PUT_LINE(rtrim(line));

     line := 'select  ';
     line := line || CHR(39);
     line := line || 'PROMPT FILES_THAT_WERE_BACKED_UP';
     line := line || CHR(39);
     line := line || ' from dual;';
     DBMS_OUTPUT.PUT_LINE(rtrim(line));

     line := 'select  ';
     line := line || CHR(39);
     line := line || '!ls -l ';
     line := line || s_path;
     line := line || '*dbf* | wc -l';
     line := line || CHR(39);
     line := line || ' from dual;';
     DBMS_OUTPUT.PUT_LINE(rtrim(line));


     line := 'select  ';
     line := line || CHR(39);
     line := line || 'spool off';
     line := line || CHR(39);
     line := line || ' from dual;';
     DBMS_OUTPUT.PUT_LINE(rtrim(line));

     /* QUIT the sqlplus session */
     line := 'select  ';
     line := line || CHR(39);
     line := line || 'quit';
     line := line || CHR(39);
     line := line || ' from dual;';
     DBMS_OUTPUT.PUT_LINE(rtrim(line));

     /* CLOSE spool file */
     line := 'spool off';
     DBMS_OUTPUT.PUT_LINE(rtrim(line));

--- Create RESTORE file statements (UNCOMPRESS)
     nCntr :=0;
     nBatch := 1;

     line := 'spool ';
     line := line || s_path;
     line := line || v_restore_name_prefix;
     line := line || nBatch;
     line := line || '.ksh';
     DBMS_OUTPUT.PUT_LINE(rtrim(line));

     line := 'select  ';
     line := line || CHR(39);
     line := line || 'cd ';
     line := line || s_path;
     line := line || CHR(39);
     line := line || ' from dual;';
     DBMS_OUTPUT.PUT_LINE(rtrim(line));

     OPEN c1;

     LOOP
        fetch c1 into v_filename,v_tablespace;
        /* Exit loop when there is no more rows to fetch */
        EXIT WHEN c1%NOTFOUND;

        line := 'select  ';
        line := line || CHR(39);
        line := line || 'gunzip -c ';
        line := line || substr( replace(replace(v_filename,'/','.'),'.oradata'),2,99);
        line := line || '.gz';
        line := line || ' > ';
        line := line || v_filename;
        line := line || CHR(39);
        line := line || ' from dual;';
        DBMS_OUTPUT.PUT_LINE(rtrim(line));

---        line := 'select  ';
---        line := line || CHR(39);
---        line := line || 'uncompress -c ';
---        line := line || s_path;
---        line := line || substr( replace(replace(v_filename,'/','.'),'.oradata'),2,99);
---        line := line || '.Z';
---        line := line || ' > ';
---        line := line || v_filename;
---        line := line || CHR(39);
---        line := line || ' from dual;';
---        DBMS_OUTPUT.PUT_LINE(rtrim(line));

         nCntr := nCntr + 1;

        IF  nCntr = s_batchsize THEN
            line := 'spool off';
            DBMS_OUTPUT.PUT_LINE(rtrim(line));

             nCntr :=0;
             nBatch := nBatch + 1;
            line := 'spool ';
            line := line || s_path;
            line := line || v_restore_name_prefix;
            line := line || nBatch;
            line := line || '.ksh';
            DBMS_OUTPUT.PUT_LINE(rtrim(line));

            line := 'select  ';
            line := line || CHR(39);
            line := line || 'cd ';
            line := line || s_path;
            line := line || CHR(39);
            line := line || ' from dual;';
            DBMS_OUTPUT.PUT_LINE(rtrim(line));
        END IF;

     END LOOP;

     /* CLOSE CURSOR */
     CLOSE c1;

     /* CLOSE spool file */
     line := 'spool off';
     DBMS_OUTPUT.PUT_LINE(rtrim(line));


END HOTBACKUP2;
/

spool off

start $OUTPUT_TO/run_cr_hot.sql


/* Clear before exiting this script */

/* EXIT Sqlplus */

exit

EOF


### Remove intermediate SQL file
#   if [ -f $OUTPUT_TO/run_cr_hot.sql ]
#   then
#      rm $OUTPUT_TO/run_cr_hot.sql
#   fi 

   ls $OUTPUT_TO/hbackup_batch*.sql > $OUTPUT_TO/hbackup.dat
   ls $OUTPUT_TO/hrestore_batch*.ksh > $OUTPUT_TO/hrestore.dat

### Create sql to run all backup scripts and ksh to mail outputs

   echo '#!/bin/ksh' > $OUTPUT_TO/hbackup_all.ksh
   echo ". $SCRIPTS/setupenv.ksh $ORACLE_SID" >> $OUTPUT_TO/hbackup_all.ksh
   echo 'cd ' $OUTPUT_TO  >> $OUTPUT_TO/hbackup_all.ksh

   cat $OUTPUT_TO/hbackup.dat | while read LINE
   do
      SCRIPTNAME=`echo $LINE | awk '{print $1}'`
      OUTNAME=`echo $LINE | awk 'BEGIN { FS = "." } {print $1}'`
      echo "nohup sqlplus / " @$SCRIPTNAME " &" >> $OUTPUT_TO/hbackup_all.ksh
      echo "@" $SCRIPTNAME >> $OUTPUT_TO/hbackup_all.sql
   done

   echo "nohup $OUTPUT_TO/hbackup_email_wait.ksh &" >> $OUTPUT_TO/hbackup_all.ksh

   rm $OUTPUT_TO/hbackup.dat

### Create .ksh to wait till all backups are complete.  Then email a single output to DBA.
   echo "#!/bin/ksh" > $OUTPUT_TO/hbackup_email_wait.ksh
   echo ". $SCRIPTS/setupenv.ksh $ORACLE_SID" >> $OUTPUT_TO/hbackup_email_wait.ksh
   echo " " >> $OUTPUT_TO/hbackup_email_wait.ksh
   echo "sleep 180  # Sleep for 180 seconds" >> $OUTPUT_TO/hbackup_email_wait.ksh
   echo "### Loop till backup batches are complete" >> $OUTPUT_TO/hbackup_email_wait.ksh

   echo "    KOUNT=\`ps -ef | grep $ORACLE_SID | grep hbackup_batch | grep -v grep | wc -l\`" >> $OUTPUT_TO/hbackup_email_wait.ksh
   echo "    while [ \$KOUNT -gt 0 ]" >> $OUTPUT_TO/hbackup_email_wait.ksh
   echo "    do" >> $OUTPUT_TO/hbackup_email_wait.ksh
   echo "        KOUNT=\`ps -ef | grep $ORACLE_SID | grep hbackup_batch | grep -v grep | wc -l\`" >> $OUTPUT_TO/hbackup_email_wait.ksh
   echo "        sleep 60  # Sleep for 60 seconds" >> $OUTPUT_TO/hbackup_email_wait.ksh
   echo "    done" >> $OUTPUT_TO/hbackup_email_wait.ksh

   echo " " >> $OUTPUT_TO/hbackup_email_wait.ksh

   echo "sqlplus / " @$OUTPUT_TO/finale_batch.sql >> $OUTPUT_TO/hbackup_email_wait.ksh

   echo "cat $OUTPUT_TO/hbackup_batch*.lst > $OUTPUT_TO/hbackup_email_wait.out " >> $OUTPUT_TO/hbackup_email_wait.ksh
   echo "MailIt '$ORACLE_SID  $DAY  Hot Backup Report ' $OUTPUT_TO/hbackup_email_wait.out $ORACLE_SID email" >> $OUTPUT_TO/hbackup_email_wait.ksh


### Create ksh to nohup all restore scripts
   echo '#!/bin/ksh' > $OUTPUT_TO/hrestore_all.ksh

   cat $OUTPUT_TO/hrestore.dat | while read LINE
   do
      SCRIPTNAME=`echo $LINE | awk '{print $1}'`
      echo "nohup " $SCRIPTNAME " &" >> $OUTPUT_TO/hrestore_all.ksh
   done
   rm $OUTPUT_TO/hrestore.dat

   chmod u+x $OUTPUT_TO/*.ksh

   echo " "
   echo "Batch Hot Backup & Restore scripts have been built in $OUTPUT_TO "

return $?
}	# End of hotbackupbatch

###-------------------------------------------------------------------------------------
function hotbackupbatchtape
{
   USAGE="Usage: hotbackupbatchtape arg1 arg2 (arg1= Batchsize, arg2= Retention Days)"

   if test "$#" -lt 2
   then
     echo $USAGE
     return 1
   fi

   typeset -i BATCHSIZE=$1
   RETPER=$2
   HOSTNAME="`hostname`"
   MASTERSERVER=`cat /usr/openv/netbackup/bp.conf | grep -n SERVER | grep 1: | grep sne | awk '{ print $3 }' FS=" "`

### Check if database instance is Up
   GetProcessStatus ora_pmon_${ORACLE_SID}
   if test "$?" -ne 0
   then
      echo "ORACLE: System PMON for ORACLE_SID=${ORACLE_SID} is not running."
      return 1
   fi

   #------------------------------------------------------------#
   #--  remove backup directories based on RETPER provided    --#
   #------------------------------------------------------------#
   if [[ $RETPER == "NONE" ]]
   then
      rm -r ${INSTANCE_OUTPUTS}/backups/HOTBKP*
   else
      find ${INSTANCE_OUTPUTS}/backups -name "HOTBKP*" -type d -mtime ${RETPER} -exec rm -r {} \; 2>>/dev/null
   fi 

   #------------------------------------------------------------#
   #--  Create new HOTBKP directory                           --#
   #------------------------------------------------------------#
   OUTPUT_TO=$INSTANCE_OUTPUTS/backups/HOTBKP$DATETIME
   mkdir -p $OUTPUT_TO

   sqlplus -s / <<EOF > /dev/null
   whenever sqlerror exit failure
   set heading on feedback off  pagesize 9999

rem
rem
rem
set linesize 300 pagesize 0 heading off verify off echo off
set serveroutput on size 700000

/* This section creates the Backup_batch.ksh files & Restore_batch.ksh */
/*  */
spool $OUTPUT_TO/run_cr_hot.sql

declare
   s_path VARCHAR(60) := '$OUTPUT_TO/';
   s_batchsize NUMBER := $BATCHSIZE;
   s_svrname VARCHAR(60) := '$HOSTNAME';
   s_masterserver VARCHAR(20) := '$MASTERSERVER';
   line VARCHAR2(300);
   v_filename	VARCHAR2(70) := ' ';
   v_tablespace VARCHAR2(30) := ' ';
   hold_tablespace VARCHAR2(30) := ' ';
   nCntr  NUMBER :=0;
   nBatch NUMBER :=1;
   v_backup_name_prefix VARCHAR2(15) := 'hbackup_batch';
   v_restore_name_prefix VARCHAR2(15) := 'hrestore_batch';

---  Tablespace Information
CURSOR c1 IS
select substr(file_name,1,70),tablespace_name
from sys.dba_data_files
order by tablespace_name,substr(file_name,1,70);


BEGIN

     line := 'spool ';
     line := line || s_path;
     line := line ||  v_backup_name_prefix;
     line := line || nBatch;
     line := line || '.sql';
     DBMS_OUTPUT.PUT_LINE(rtrim(line));

     line := 'select  ';
     line := line || CHR(39);
     line := line || 'define DBInstance = \$ORACLE_SID';
     line := line || CHR(39);
     line := line || ' from dual;';
     DBMS_OUTPUT.PUT_LINE(rtrim(line));

     line := 'select  ';
     line := line || CHR(39);
     line := line || '@\$SCRIPTS/setupenv.sql \$ORACLE_SID';
     line := line || CHR(39);
     line := line || ' from dual;';
     DBMS_OUTPUT.PUT_LINE(rtrim(line));

     line := 'select  ';
     line := line || CHR(39);
     line := line || 'set linesize 300 heading off';
     line := line || CHR(39);
     line := line || ' from dual;';
     DBMS_OUTPUT.PUT_LINE(rtrim(line));

     line := 'select  ';
     line := line || CHR(39);
     line := line || 'spool ';
     line := line || s_path;
     line := line || v_backup_name_prefix;
     line := line || nBatch;
     line := line || '.lst';
     line := line || CHR(39);
     line := line || ' from dual;';
     DBMS_OUTPUT.PUT_LINE(rtrim(line));

--- Create backup file statements (Compress)
     OPEN c1;

     fetch c1 into v_filename,v_tablespace;

     LOOP

---     Write begin tablespace backup
        IF v_tablespace != hold_tablespace THEN

           hold_tablespace := v_tablespace;

           line := 'select  ';
           line := line || CHR(39);
           line := line || 'prompt ';
           line := line || 'Begin Backup of ';
           line := line ||  v_tablespace;
           line := line || CHR(39);
           line := line || ' from dual;';
           DBMS_OUTPUT.PUT_LINE(rtrim(line));

           line := 'select  ';
           line := line || CHR(39);
           line := line || 'alter tablespace ';
           line := line || v_tablespace;
           line := line || ' begin backup ;';
           line := line || CHR(39);
           line := line || ' from dual;';
           DBMS_OUTPUT.PUT_LINE(rtrim(line));

        END IF;

---     Build backup statement for datafile
        line := 'select  ';
        line := line || CHR(39);
        line := line || '!/usr/openv/netbackup/bin/bpbackup -p ';
        line := line || UPPER(s_svrname);
        line := line || ' -s ';
        line := line || s_svrname;
        line := line || '_user';
        line := line || ' -h ';
        line := line || s_svrname;
        line := line || ' -S ';
        line := line || rtrim(s_masterserver);
        line := line || ' -w 0 ';
        line := line || ' -L ';
        line := line || s_path;
        line := line || 'backup_progress.log ';
        line := line || v_filename;
        line := line || CHR(39);
        line := line || ' from dual;';
        DBMS_OUTPUT.PUT_LINE(rtrim(line));



        /* Increment datafile procecessed counter */
        nCntr := nCntr + 1;

        fetch c1 into v_filename,v_tablespace;
        /* Exit loop when there is no more rows to fetch */
        EXIT WHEN c1%NOTFOUND;

        IF v_tablespace != hold_tablespace THEN
           line := 'select  ';
           line := line || CHR(39);
           line := line || 'alter tablespace ';
           line := line || hold_tablespace;
           line := line || ' end backup ;';
           line := line || CHR(39);
           line := line || ' from dual;';
           DBMS_OUTPUT.PUT_LINE(rtrim(line));

           line := 'select  ';
           line := line || CHR(39);
           line := line || 'prompt ';
           line := line || 'End Backup of ';
           line := line ||  hold_tablespace;
           line := line || CHR(39);
           line := line || ' from dual;';
           DBMS_OUTPUT.PUT_LINE(rtrim(line));

           IF nCntr >= s_batchsize THEN 
              line := 'select  ';
              line := line || CHR(39);
              line := line || 'spool off';
              line := line || CHR(39);
              line := line || ' from dual;';
              DBMS_OUTPUT.PUT_LINE(rtrim(line));

              line := 'select  ';
              line := line || CHR(39);
              line := line || 'quit';
              line := line || CHR(39);
              line := line || ' from dual;';
              DBMS_OUTPUT.PUT_LINE(rtrim(line));

              line := 'spool off';
              DBMS_OUTPUT.PUT_LINE(rtrim(line));

              nCntr :=0;
              nBatch := nBatch + 1;
              line := 'spool ';

              line := line || s_path;
              line := line || v_backup_name_prefix;
              line := line || nBatch;
              line := line || '.sql';
              DBMS_OUTPUT.PUT_LINE(rtrim(line));

              line := 'select  ';
              line := line || CHR(39);
              line := line || 'define DBInstance = \$ORACLE_SID';
              line := line || CHR(39);
              line := line || ' from dual;';
              DBMS_OUTPUT.PUT_LINE(rtrim(line));

              line := 'select  ';
              line := line || CHR(39);
              line := line || '@\$SCRIPTS/setupenv.sql \$ORACLE_SID ';
              line := line || CHR(39);
              line := line || ' from dual;';
              DBMS_OUTPUT.PUT_LINE(rtrim(line));

              line := 'select  ';
              line := line || CHR(39);
              line := line || 'set linesize 300 heading off';
              line := line || CHR(39);
              line := line || ' from dual;';
              DBMS_OUTPUT.PUT_LINE(rtrim(line));

              line := 'select  ';
              line := line || CHR(39);
              line := line || 'spool ';
              line := line || s_path;
              line := line || v_backup_name_prefix;
              line := line || nBatch;
              line := line || '.lst';
              line := line || CHR(39);
              line := line || ' from dual;';
              DBMS_OUTPUT.PUT_LINE(rtrim(line));
           END IF;
        END IF;


     END LOOP;

     /* CLOSE CURSOR */
     CLOSE c1;

     line := 'select  ';
     line := line || CHR(39);
     line := line || 'alter tablespace ';
     line := line || hold_tablespace;
     line := line || ' end backup ;';
     line := line || CHR(39);
     line := line || ' from dual;';
     DBMS_OUTPUT.PUT_LINE(rtrim(line));

     line := 'select  ';
     line := line || CHR(39);
     line := line || 'prompt ';
     line := line || 'End Backup of ';
     line := line ||  hold_tablespace;
     line := line || CHR(39);
     line := line || ' from dual;';
     DBMS_OUTPUT.PUT_LINE(rtrim(line));

     line := 'select  ';
     line := line || CHR(39);
     line := line || 'spool off';
     line := line || CHR(39);
     line := line || ' from dual;';
     DBMS_OUTPUT.PUT_LINE(rtrim(line));

     /* QUIT the sqlplus session */
     line := 'select  ';
     line := line || CHR(39);
     line := line || 'quit';
     line := line || CHR(39);
     line := line || ' from dual;';
     DBMS_OUTPUT.PUT_LINE(rtrim(line));

     line := 'spool off';
     DBMS_OUTPUT.PUT_LINE(rtrim(line));

     /*------------------------------------------------------------------------------------*/
     /* Create finale SQL file to backup controlfile and list logfile info. */
     nCntr :=0;
     nBatch := nBatch + 1;
     line := 'spool ';
     line := line || s_path;
     line := line || 'finale_batch';
     line := line || '.sql';
     DBMS_OUTPUT.PUT_LINE(rtrim(line));

     line := 'select  ';
     line := line || CHR(39);
     line := line || 'spool ';
     line := line || s_path;
     line := line || v_backup_name_prefix;
     line := line || nBatch;
     line := line || '.lst';
     line := line || CHR(39);
     line := line || ' from dual;';
     DBMS_OUTPUT.PUT_LINE(rtrim(line));

     line := 'select  ';
     line := line || CHR(39);
     line := line || 'set linesize 300 pagesize 200';
     line := line || CHR(39);
     line := line || ' from dual;';
     DBMS_OUTPUT.PUT_LINE(rtrim(line));

     line := 'select  ';
     line := line || CHR(39);
     line := line || 'prompt Start Backup of controlfile ';
     line := line || CHR(39);
     line := line || ' from dual;';
     DBMS_OUTPUT.PUT_LINE(rtrim(line));


     /* Perform logfile switch */ 
     line := 'prompt  alter system switch logfile';
     DBMS_OUTPUT.PUT_LINE(rtrim(line));

     line := 'select  ';
     line := line || CHR(39);
     line := line || ';';
     line := line || CHR(39);
     line := line || ' from dual;';
     DBMS_OUTPUT.PUT_LINE(rtrim(line));

     /* Backup controlfile */ 
     line := 'prompt  ';
     line := line || 'alter database backup controlfile to ';
     line := line || CHR(39);
     line := line || s_path;
     line := line || 'backup.ctl_';
     line := line || to_char(sysdate,'YYYYMMDD.HH24MISS');
     line := line || CHR(39);
     DBMS_OUTPUT.PUT_LINE(rtrim(line));

     line := 'select  ';
     line := line || CHR(39);
     line := line || ';';
     line := line || CHR(39);
     line := line || ' from dual;';
     DBMS_OUTPUT.PUT_LINE(rtrim(line));

     line := 'select  ';
     line := line || CHR(39);
     line := line || 'prompt End Backup of controlfile ';
     line := line || CHR(39);
     line := line || ' from dual;';
     DBMS_OUTPUT.PUT_LINE(rtrim(line));

     line := 'select  ';
     line := line || CHR(39);
     line := line || 'select substr(member,1,70) MEMBER from v\$logfile;';
     line := line || CHR(39);
     line := line || ' from dual;';
     DBMS_OUTPUT.PUT_LINE(rtrim(line));

     line := 'select  ';
     line := line || CHR(39);
     line := line || 'select substr(d.name,1,45) DATAFILE, b.status, b.time, b.change#  from v\$backup b, v\$datafile d where b.file# = d.file#;';
     line := line || CHR(39);
     line := line || ' from dual;';
     DBMS_OUTPUT.PUT_LINE(rtrim(line));

     line := 'select  ';
     line := line || CHR(39);
     line := line || 'spool off';
     line := line || CHR(39);
     line := line || ' from dual;';
     DBMS_OUTPUT.PUT_LINE(rtrim(line));

     /* QUIT the sqlplus session */
     line := 'select  ';
     line := line || CHR(39);
     line := line || 'quit';
     line := line || CHR(39);
     line := line || ' from dual;';
     DBMS_OUTPUT.PUT_LINE(rtrim(line));

     /* CLOSE spool file */
     line := 'spool off';
     DBMS_OUTPUT.PUT_LINE(rtrim(line));

END HOTBACKUP2;
/

spool off

start $OUTPUT_TO/run_cr_hot.sql


/* Clear before exiting this script */

/* EXIT Sqlplus */

exit

EOF


### Remove intermediate SQL file
   if [ -f $OUTPUT_TO/run_cr_hot.sql ]
   then
#       echo "Disabled remove intermediate sql"
      rm $OUTPUT_TO/run_cr_hot.sql
   fi 

   ls $OUTPUT_TO/hbackup_batch*.sql > $OUTPUT_TO/hbackup.dat

### Create sql to run all backup scripts and ksh to mail outputs

   echo '#!/bin/ksh' > $OUTPUT_TO/hbackup_all.ksh
   echo ". $SCRIPTS/setupenv.ksh $ORACLE_SID" >> $OUTPUT_TO/hbackup_all.ksh

   cat $OUTPUT_TO/hbackup.dat | while read LINE
   do
      SCRIPTNAME=`echo $LINE | awk '{print $1}'`
      OUTNAME=`echo $LINE | awk 'BEGIN { FS = "." } {print $1}'`
      echo "nohup sqlplus / " @$SCRIPTNAME " &" >> $OUTPUT_TO/hbackup_all.ksh
      echo "@" $SCRIPTNAME >> $OUTPUT_TO/hbackup_all.sql
   done

   echo "nohup $OUTPUT_TO/hbackup_email_wait.ksh &" >> $OUTPUT_TO/hbackup_all.ksh

   rm $OUTPUT_TO/hbackup.dat

### Create .ksh to wait till all backups are complete.  Then email a single output to DBA.
   echo "#!/bin/ksh" > $OUTPUT_TO/hbackup_email_wait.ksh
   echo ". $SCRIPTS/setupenv.ksh $ORACLE_SID" >> $OUTPUT_TO/hbackup_email_wait.ksh
   echo " " >> $OUTPUT_TO/hbackup_email_wait.ksh
   echo "sleep 180  # Sleep for 180 seconds" >> $OUTPUT_TO/hbackup_email_wait.ksh
   echo "### Loop till backup batches are complete" >> $OUTPUT_TO/hbackup_email_wait.ksh

   echo "    KOUNT=\`ps -ef | grep bpbackup | grep -v grep | wc -l\`" >> $OUTPUT_TO/hbackup_email_wait.ksh
   echo "    while [ \$KOUNT -gt 0 ]" >> $OUTPUT_TO/hbackup_email_wait.ksh
   echo "    do" >> $OUTPUT_TO/hbackup_email_wait.ksh
   echo "        KOUNT=\`ps -ef | grep bpbackup | grep -v grep | wc -l\`" >> $OUTPUT_TO/hbackup_email_wait.ksh
   echo "        sleep 60  # Sleep for 60 seconds" >> $OUTPUT_TO/hbackup_email_wait.ksh
   echo "    done" >> $OUTPUT_TO/hbackup_email_wait.ksh

   echo " " >> $OUTPUT_TO/hbackup_email_wait.ksh

   echo "sqlplus / " @$OUTPUT_TO/finale_batch.sql >> $OUTPUT_TO/hbackup_email_wait.ksh

   echo "cat $OUTPUT_TO/hbackup_batch*.lst > $OUTPUT_TO/hbackup_email_wait.out " >> $OUTPUT_TO/hbackup_email_wait.ksh
   echo "MailIt '$ORACLE_SID  $DAY  Hot Backup Report ' $OUTPUT_TO/hbackup_email_wait.out $ORACLE_SID email" >> $OUTPUT_TO/hbackup_email_wait.ksh


   chmod u+x $OUTPUT_TO/*.ksh

   echo " "
   echo "Batch Hot Backup scripts to tape have been built in $OUTPUT_TO "

return $?
}	# End of hotbackupbatchtape


###-------------------------------------------------------------------------------------
function coldbackupbatch
{
   USAGE="Usage: coldbackupbatch arg1 arg2 (arg1= Batchsize, arg2= Retention Days)"

   if test "$#" -lt 2
   then
     echo $USAGE
     return 1
   fi

   typeset -i BATCHSIZE=$1
   RETPER=$2 
 

### Check if database instance is Up
   GetProcessStatus ora_pmon_${ORACLE_SID}
   if test "$?" -ne 0
   then
      echo "ORACLE: System PMON for ORACLE_SID=${ORACLE_SID} is not running."
      return 1
   fi


   #------------------------------------------------------------#
   #--  remove backup directories based on RETPER provided    --#
   #------------------------------------------------------------#

   find ${INSTANCE_OUTPUTS}/backups -name "COLDBKP*" -type d -mtime ${RETPER} -exec rm -r {} \; 2>>/dev/null 

   #------------------------------------------------------------#
   #--  Create COLDBKP directory                              --#
   #------------------------------------------------------------#
   OUTPUT_TO=$INSTANCE_OUTPUTS/backups/COLDBKP$DATETIME
   mkdir -p $OUTPUT_TO


   sqlplus -s / <<EOF > /dev/null
   whenever sqlerror exit failure
   set heading on feedback off  pagesize 9999

rem
rem
rem
set linesize 255 pagesize 0 heading off verify off echo off
set serveroutput on size 700000

/* This section creates the Backup_batch.ksh files & Restore_batch.ksh */
/*  */
spool $OUTPUT_TO/run_cr_cold.sql

declare
   s_path VARCHAR(60) := '$OUTPUT_TO/';
   s_batchsize NUMBER := $BATCHSIZE;
   line VARCHAR2(255);
   v_filename	VARCHAR2(70);
   nCntr  NUMBER :=0;
   nBatch NUMBER :=1;
   v_backup_name_prefix VARCHAR2(15) := 'cbackup_batch';
   v_restore_name_prefix VARCHAR2(15) := 'crestore_batch';

---  Tablespace Information
CURSOR c1 IS
select substr(file_name,1,70)
from sys.dba_data_files
UNION
select substr(member,1,70)
from v\$logfile
UNION
select substr(name,1,70)
from v\$controlfile;


BEGIN

     line := 'spool ';
     line := line || s_path;
     line := line ||  v_backup_name_prefix;
     line := line || nBatch;
     line := line || '.ksh';
     DBMS_OUTPUT.PUT_LINE(rtrim(line));

--- Add environment setup execution
     line := 'select ';
     line := line || CHR(39);
     line := line || '#!/bin/ksh';
     line := line || CHR(39);
     line := line || ' from dual;';
     DBMS_OUTPUT.PUT_LINE(rtrim(line));

     line := 'select  ';
     line := line || CHR(39);
     line := line || '. $SCRIPTS/setupenv.ksh $ORACLE_SID';
     line := line || CHR(39);
     line := line || ' from dual;';
     DBMS_OUTPUT.PUT_LINE(rtrim(line));

--- Add check for database being down
     line := 'select  ';
     line := line || CHR(39);
     line := line || 'GetProcessStatus ora_pmon_${ORACLE_SID}';
     line := line || CHR(39);
     line := line || ' from dual;';
     DBMS_OUTPUT.PUT_LINE(rtrim(line));

     line := 'select  ';
     line := line || CHR(39);
     line := line || 'if test ';
     line := line || CHR(34);
     line := line || CHR(36);
     line := line || CHR(63);
     line := line || CHR(34);
     line := line || ' -eq 0';
     line := line || CHR(39);
     line := line || ' from dual;';
     DBMS_OUTPUT.PUT_LINE(rtrim(line));

     line := 'select  ';
     line := line || CHR(39);
     line := line || 'then';
     line := line || CHR(39);
     line := line || ' from dual;';
     DBMS_OUTPUT.PUT_LINE(rtrim(line));

     line := 'select  ';
     line := line || CHR(39);
     line := line || '   echo "${ORACLE_SID} is running, please shutdown the database."';
     line := line || CHR(39);
     line := line || ' from dual;';
     DBMS_OUTPUT.PUT_LINE(rtrim(line));

     line := 'select  ';
     line := line || CHR(39);
     line := line || '   return 1';
     line := line || CHR(39);
     line := line || ' from dual;';
     DBMS_OUTPUT.PUT_LINE(rtrim(line));

     line := 'select  ';
     line := line || CHR(39);
     line := line || 'fi';
     line := line || CHR(39);
     line := line || ' from dual;';
     DBMS_OUTPUT.PUT_LINE(rtrim(line));

     line := 'select ';
     line := line || CHR(39);
     line := line || 'cd ';
     line := line || s_path;
     line := line || CHR(39);
     line := line || ' from dual;';
     DBMS_OUTPUT.PUT_LINE(rtrim(line));

--- Create backup file statements (Compress)
     OPEN c1;

     LOOP
        fetch c1 into v_filename;
        /* Exit loop when there is no more rows to fetch */
        EXIT WHEN c1%NOTFOUND;

---     Build backup statement for datafile
        line := 'select  ';
        line := line || CHR(39);
        line := line || 'gzip -c ';
        line := line || v_filename;
        line := line || ' > ';
        line := line || substr( replace(replace(v_filename,'/','.'),'.oradata'),2,99);
        line := line || '.gz';
        line := line || CHR(39);
        line := line || ' from dual;';
        DBMS_OUTPUT.PUT_LINE(rtrim(line));

---        line := 'select  ';
---        line := line || CHR(39);
---        line := line || 'compress < ';
---        line := line || v_filename;
---        line := line || ' > ';
---        line := line || s_path;
---        line := line || substr( replace(replace(v_filename,'/','.'),'.oradata'),2,99);
---        line := line || '.Z ';
----        line := line || ' && print ';
----        line := line || CHR(34);
----        line := line || v_filename;        
----        line := line || CHR(34);
----        line := line || ' >> ';
----        line := line || s_path;
----        line := line || ' compress.log';
----        line := line || ' || print ';
----        line := line || CHR(34);
----        line := line || v_filename;
----        line := line || ' FAILED ';
----        line := line || CHR(34);
----        line := line || ' >> ';
----        line := line || s_path;
----        line := line || ' compress.log ';
---        line := line || CHR(39);
---        line := line || ' from dual;';
---        DBMS_OUTPUT.PUT_LINE(rtrim(line));

---     Build ls -l of backup file to log
        line := 'select  ';
        line := line || CHR(39);
        line := line || 'ls -l ';
        line := line || substr( replace(replace(v_filename,'/','.'),'.oradata'),2,99);
        line := line || '.gz';
        line := line || ' >> ';
        line := line || 'compress.log';
        line := line || ' 2>> ';
        line := line || 'compress.log';
        line := line || CHR(39);
        line := line || ' from dual;';
        DBMS_OUTPUT.PUT_LINE(rtrim(line));

---     Build ls -l of missing backup file to log
---        line := 'select  ';
---        line := line || CHR(39);
---        line := line || 'ls -l ';
---        line := line || s_path;
---        line := line || substr( replace(replace(v_filename,'/','.'),'.oradata'),2,99);
---        line := line || '.Z';
---        line := line || ' 2>> ';
---        line := line || s_path;
---        line := line || 'compress.log';
---        line := line || CHR(39);
---        line := line || ' from dual;';
---        DBMS_OUTPUT.PUT_LINE(rtrim(line));

        /* Increment datafile procecessed counter */
        nCntr := nCntr + 1;

        IF  nCntr = s_batchsize THEN 
            line := 'spool off';
            DBMS_OUTPUT.PUT_LINE(rtrim(line));

            nCntr :=0;
            nBatch := nBatch + 1;
            line := 'spool ';
            line := line || s_path;
            line := line || v_backup_name_prefix;
            line := line || nBatch;
            line := line || '.ksh';
            DBMS_OUTPUT.PUT_LINE(rtrim(line));

            --- Add environment setup execution
            line := 'select ';
            line := line || CHR(39);
            line := line || '#!/bin/ksh';
            line := line || CHR(39);
            line := line || ' from dual;';
            DBMS_OUTPUT.PUT_LINE(rtrim(line));

            line := 'select  ';
            line := line || CHR(39);
            line := line || '. $SCRIPTS/setupenv.ksh $ORACLE_SID';
            line := line || CHR(39);
            line := line || ' from dual;';
            DBMS_OUTPUT.PUT_LINE(rtrim(line));

            --- Add check for database being down
            line := 'select  ';
            line := line || CHR(39);
            line := line || 'GetProcessStatus ora_pmon_${ORACLE_SID}';
            line := line || CHR(39);
            line := line || ' from dual;';
            DBMS_OUTPUT.PUT_LINE(rtrim(line));

            line := 'select  ';
            line := line || CHR(39);
            line := line || 'if test ';
            line := line || CHR(34);
            line := line || CHR(36);
            line := line || CHR(63);
            line := line || CHR(34);
            line := line || ' -eq 0';
            line := line || CHR(39);
            line := line || ' from dual;';
            DBMS_OUTPUT.PUT_LINE(rtrim(line));

            line := 'select  ';
            line := line || CHR(39);
            line := line || 'then';
            line := line || CHR(39);
            line := line || ' from dual;';
            DBMS_OUTPUT.PUT_LINE(rtrim(line));

            line := 'select  ';
            line := line || CHR(39);
            line := line || '   echo "${ORACLE_SID} is running, please shutdown the database."';
            line := line || CHR(39);
            line := line || ' from dual;';
            DBMS_OUTPUT.PUT_LINE(rtrim(line));

            line := 'select  ';
            line := line || CHR(39);
            line := line || '   return 1';
            line := line || CHR(39);
            line := line || ' from dual;';
            DBMS_OUTPUT.PUT_LINE(rtrim(line));

            line := 'select  ';
            line := line || CHR(39);
            line := line || 'fi';
            line := line || CHR(39);
            line := line || ' from dual;';
            DBMS_OUTPUT.PUT_LINE(rtrim(line));

            line := 'select ';
            line := line || CHR(39);
            line := line || 'cd ';
            line := line || s_path;
            line := line || CHR(39);
            line := line || ' from dual;';
            DBMS_OUTPUT.PUT_LINE(rtrim(line));

        END IF;

     END LOOP;

     /* CLOSE CURSOR */
     CLOSE c1;

     line := 'spool off';
     DBMS_OUTPUT.PUT_LINE(rtrim(line));

--- Create restore file statements (Uncompress)
     nCntr :=0;
     nBatch := 1;

     line := 'spool ';
     line := line || s_path;
     line := line || v_restore_name_prefix;
     line := line || nBatch;
     line := line || '.ksh';
     DBMS_OUTPUT.PUT_LINE(rtrim(line));

     line := 'select ';
     line := line || CHR(39);
     line := line || 'cd ';
     line := line || s_path;
     line := line || CHR(39);
     line := line || ' from dual;';
     DBMS_OUTPUT.PUT_LINE(rtrim(line));

     OPEN c1;

     LOOP
        fetch c1 into v_filename;
        /* Exit loop when there is no more rows to fetch */
        EXIT WHEN c1%NOTFOUND;


        line := 'select  ';
        line := line || CHR(39);
        line := line || 'gunzip -c ';
        line := line || substr( replace(replace(v_filename,'/','.'),'.oradata'),2,99);
        line := line || '.gz';
        line := line || ' > ';
        line := line || v_filename;
        line := line || CHR(39);
        line := line || ' from dual;';
        DBMS_OUTPUT.PUT_LINE(rtrim(line));

---        line := 'select  ';
---        line := line || CHR(39);
---        line := line || 'uncompress -c ';
---        line := line || s_path;
---        line := line || substr( replace(replace(v_filename,'/','.'),'.oradata'),2,99);
---        line := line || '.Z';
---        line := line || ' > ';
---        line := line || v_filename;
---        line := line || CHR(39);
---        line := line || ' from dual;';
---        DBMS_OUTPUT.PUT_LINE(rtrim(line));

         nCntr := nCntr + 1;

        IF  nCntr = s_batchsize THEN
            line := 'spool off';
            DBMS_OUTPUT.PUT_LINE(rtrim(line));

             nCntr :=0;
             nBatch := nBatch + 1;
            line := 'spool ';
            line := line || s_path;
            line := line || v_restore_name_prefix;
            line := line || nBatch;
            line := line || '.ksh';
            DBMS_OUTPUT.PUT_LINE(rtrim(line));

            line := 'select ';
            line := line || CHR(39);
            line := line || 'cd ';
            line := line || s_path;
            line := line || CHR(39);
            line := line || ' from dual;';
            DBMS_OUTPUT.PUT_LINE(rtrim(line));

        END IF;

     END LOOP;

     /* CLOSE CURSOR */
     CLOSE c1;

     line := 'spool off';
     DBMS_OUTPUT.PUT_LINE(rtrim(line));


END AEDBA_BACKUP_RESTORE;
/

spool off

start $OUTPUT_TO/run_cr_cold.sql


/* Clear before exiting this script */

/* EXIT Sqlplus */

exit

EOF

###   if [ -f $OUTPUT_TO/run_cr_cold.sql ]
###   then
###      rm $OUTPUT_TO/run_cr_cold.sql
###   fi 

   ls $OUTPUT_TO/cbackup_batch*.ksh > $OUTPUT_TO/cbackup.lst
   ls $OUTPUT_TO/crestore_batch*.ksh > $OUTPUT_TO/crestore.lst

### Create ksh to nohup all backup scripts
   cat $OUTPUT_TO/cbackup.lst | while read LINE
   do
      SCRIPTNAME=`echo $LINE | awk '{print $1}'`
      echo "nohup " $SCRIPTNAME " &" >> $OUTPUT_TO/cbackup_all.ksh
   done
   rm $OUTPUT_TO/cbackup.lst

### Create ksh to nohup all restore scripts
   cat $OUTPUT_TO/crestore.lst | while read LINE
   do
      SCRIPTNAME=`echo $LINE | awk '{print $1}'`
      echo "nohup " $SCRIPTNAME " &" >> $OUTPUT_TO/crestore_all.ksh
   done
   rm $OUTPUT_TO/crestore.lst

### Make ksh scripts executable
   chmod u+x $OUTPUT_TO/cbackup_batch*.ksh
   chmod u+x $OUTPUT_TO/cbackup_all.ksh

   echo " "
   echo "Batch Cold Backup & Restore scripts have been built in $OUTPUT_TO "

return $?
}	#End of coldbackupbatch


###-------------------------------------------------------------------------------------
function coldbackupbatchtape
{
   USAGE="Usage: coldbackupbatchtape arg1 arg2 (arg1= Batchsize, arg2= Retention Days)"

   if test "$#" -lt 2
   then
     echo $USAGE
     return 1
   fi

   typeset -i BATCHSIZE=$1
   RETPER=$2 
   HOSTNAME="`hostname`"
   MASTERSERVER=`cat /usr/openv/netbackup/bp.conf | grep -n SERVER | grep 1: | grep sne | awk '{ print $3 }' FS=" "`

### Check if database instance is Up
   GetProcessStatus ora_pmon_${ORACLE_SID}
   if test "$?" -ne 0
   then
      echo "ORACLE: System PMON for ORACLE_SID=${ORACLE_SID} is not running."
      return 1
   fi


   #------------------------------------------------------------#
   #--  remove backup directories based on RETPER provided    --#
   #------------------------------------------------------------#

   find ${INSTANCE_OUTPUTS}/backups -name "COLDBKP*" -type d -mtime ${RETPER} -exec rm -r {} \; 2>>/dev/null 

   #------------------------------------------------------------#
   #--  Create COLDBKP directory                              --#
   #------------------------------------------------------------#
   OUTPUT_TO=$INSTANCE_OUTPUTS/backups/COLDBKP$DATETIME
   mkdir -p $OUTPUT_TO


   sqlplus -s / <<EOF > /dev/null
   whenever sqlerror exit failure
   set heading on feedback off  pagesize 9999

rem
rem
rem
set linesize 255 pagesize 0 heading off verify off echo off
set serveroutput on size 700000

/* This section creates the Backup_batch.ksh files & Restore_batch.ksh */
/*  */
spool $OUTPUT_TO/run_cr_cold.sql

declare
   s_path VARCHAR(60) := '$OUTPUT_TO/';
   s_batchsize NUMBER := $BATCHSIZE;
   s_svrname VARCHAR(60) := '$HOSTNAME';
   s_masterserver VARCHAR(20) := '$MASTERSERVER';
   line VARCHAR2(300);
   v_filename	VARCHAR2(70);
   nCntr  NUMBER :=0;
   nBatch NUMBER :=1;
   v_backup_name_prefix VARCHAR2(15) := 'cbackup_batch';
   v_restore_name_prefix VARCHAR2(15) := 'crestore_batch';

---  Tablespace Information
CURSOR c1 IS
select substr(file_name,1,70)
from sys.dba_data_files
UNION
select substr(member,1,70)
from v\$logfile
UNION
select substr(name,1,70)
from v\$controlfile;


BEGIN

     line := 'spool ';
     line := line || s_path;
     line := line ||  v_backup_name_prefix;
     line := line || nBatch;
     line := line || '.ksh';
     DBMS_OUTPUT.PUT_LINE(rtrim(line));

--- Add environment setup execution
     line := 'select ';
     line := line || CHR(39);
     line := line || '#!/bin/ksh';
     line := line || CHR(39);
     line := line || ' from dual;';
     DBMS_OUTPUT.PUT_LINE(rtrim(line));

     line := 'select  ';
     line := line || CHR(39);
     line := line || '. $SCRIPTS/setupenv.ksh $ORACLE_SID';
     line := line || CHR(39);
     line := line || ' from dual;';
     DBMS_OUTPUT.PUT_LINE(rtrim(line));

--- Add check for database being down
     line := 'select  ';
     line := line || CHR(39);
     line := line || 'GetProcessStatus ora_pmon_${ORACLE_SID}';
     line := line || CHR(39);
     line := line || ' from dual;';
     DBMS_OUTPUT.PUT_LINE(rtrim(line));

     line := 'select  ';
     line := line || CHR(39);
     line := line || 'if test ';
     line := line || CHR(34);
     line := line || CHR(36);
     line := line || CHR(63);
     line := line || CHR(34);
     line := line || ' -eq 0';
     line := line || CHR(39);
     line := line || ' from dual;';
     DBMS_OUTPUT.PUT_LINE(rtrim(line));

     line := 'select  ';
     line := line || CHR(39);
     line := line || 'then';
     line := line || CHR(39);
     line := line || ' from dual;';
     DBMS_OUTPUT.PUT_LINE(rtrim(line));

     line := 'select  ';
     line := line || CHR(39);
     line := line || '   echo "${ORACLE_SID} is running, please shutdown the database."';
     line := line || CHR(39);
     line := line || ' from dual;';
     DBMS_OUTPUT.PUT_LINE(rtrim(line));

     line := 'select  ';
     line := line || CHR(39);
     line := line || '   return 1';
     line := line || CHR(39);
     line := line || ' from dual;';
     DBMS_OUTPUT.PUT_LINE(rtrim(line));

     line := 'select  ';
     line := line || CHR(39);
     line := line || 'fi';
     line := line || CHR(39);
     line := line || ' from dual;';
     DBMS_OUTPUT.PUT_LINE(rtrim(line));


--- Create backup file statements (Compress)
     OPEN c1;

     LOOP
        fetch c1 into v_filename;
        /* Exit loop when there is no more rows to fetch */
        EXIT WHEN c1%NOTFOUND;

---     Build backup statement for datafile
        line := 'select  ';
        line := line || CHR(39);
        line := line || '/usr/openv/netbackup/bin/bpbackup -p ';
        line := line || UPPER(s_svrname);
        line := line || ' -s ';
        line := line || s_svrname;
        line := line || '_user';
        line := line || ' -h ';
        line := line || s_svrname;
        line := line || ' -S ';
        line := line || rtrim(s_masterserver);
        line := line || ' -w 0 ';
        line := line || ' -L ';
        line := line || s_path;
        line := line || 'backup_progress.log ';
        line := line || v_filename;
        line := line || CHR(39);
        line := line || ' from dual;';
        DBMS_OUTPUT.PUT_LINE(rtrim(line));


         nCntr := nCntr + 1;

        IF  nCntr = s_batchsize THEN 
            line := 'spool off';
            DBMS_OUTPUT.PUT_LINE(rtrim(line));

            nCntr :=0;
            nBatch := nBatch + 1;
            line := 'spool ';
            line := line || s_path;
            line := line || v_backup_name_prefix;
            line := line || nBatch;
            line := line || '.ksh';
            DBMS_OUTPUT.PUT_LINE(rtrim(line));

            --- Add environment setup execution
            line := 'select ';
            line := line || CHR(39);
            line := line || '#!/bin/ksh';
            line := line || CHR(39);
            line := line || ' from dual;';
            DBMS_OUTPUT.PUT_LINE(rtrim(line));

            line := 'select  ';
            line := line || CHR(39);
            line := line || '. $SCRIPTS/setupenv.ksh $ORACLE_SID';
            line := line || CHR(39);
            line := line || ' from dual;';
            DBMS_OUTPUT.PUT_LINE(rtrim(line));

            --- Add check for database being down
            line := 'select  ';
            line := line || CHR(39);
            line := line || 'GetProcessStatus ora_pmon_${ORACLE_SID}';
            line := line || CHR(39);
            line := line || ' from dual;';
            DBMS_OUTPUT.PUT_LINE(rtrim(line));

            line := 'select  ';
            line := line || CHR(39);
            line := line || 'if test ';
            line := line || CHR(34);
            line := line || CHR(36);
            line := line || CHR(63);
            line := line || CHR(34);
            line := line || ' -eq 0';
            line := line || CHR(39);
            line := line || ' from dual;';
            DBMS_OUTPUT.PUT_LINE(rtrim(line));

            line := 'select  ';
            line := line || CHR(39);
            line := line || 'then';
            line := line || CHR(39);
            line := line || ' from dual;';
            DBMS_OUTPUT.PUT_LINE(rtrim(line));

            line := 'select  ';
            line := line || CHR(39);
            line := line || '   echo "${ORACLE_SID} is running, please shutdown the database."';
            line := line || CHR(39);
            line := line || ' from dual;';
            DBMS_OUTPUT.PUT_LINE(rtrim(line));

            line := 'select  ';
            line := line || CHR(39);
            line := line || '   return 1';
            line := line || CHR(39);
            line := line || ' from dual;';
            DBMS_OUTPUT.PUT_LINE(rtrim(line));

            line := 'select  ';
            line := line || CHR(39);
            line := line || 'fi';
            line := line || CHR(39);
            line := line || ' from dual;';
            DBMS_OUTPUT.PUT_LINE(rtrim(line));

        END IF;

     END LOOP;

     /* CLOSE CURSOR */
     CLOSE c1;

     line := 'spool off';
     DBMS_OUTPUT.PUT_LINE(rtrim(line));


END AEDBA_BACKUP_RESTORE;
/

spool off

start $OUTPUT_TO/run_cr_cold.sql


/* Clear before exiting this script */

/* EXIT Sqlplus */

exit

EOF

   if [ -f $OUTPUT_TO/run_cr_cold.sql ]
   then
      rm $OUTPUT_TO/run_cr_cold.sql
   fi 

   ls $OUTPUT_TO/cbackup_batch*.ksh > $OUTPUT_TO/cbackup.lst

### Create ksh to nohup all backup scripts
   cat $OUTPUT_TO/cbackup.lst | while read LINE
   do
      SCRIPTNAME=`echo $LINE | awk '{print $1}'`
      echo "nohup " $SCRIPTNAME " &" >> $OUTPUT_TO/cbackup_all.ksh
   done
   rm $OUTPUT_TO/cbackup.lst

### Make ksh scripts executable
   chmod u+x $OUTPUT_TO/cbackup_batch*.ksh
   chmod u+x $OUTPUT_TO/cbackup_all.ksh

   echo " "
   echo "Batch Cold Backup scripts to tape have been built in $OUTPUT_TO "

return $?
}	# End of coldbackupbatchtape


###-------------------------------------------------------------------------------------
function db_verify
{
   USAGE="Usage: db_verify  (no arguments)"

#   if test "$#" -lt 1
#   then
#     echo $USAGE
#     return 1
#   fi

   mailist=dba 

   OUTPUT_PATH=$SCRIPTS/out
   MERGED=$OUTPUT_PATH/db_verify_$ORACLE_SID.out

   export OUTPUT=$SCRIPTS/dynamic/db_verify_${ORACLE_SID}.ksh
   if [ -f $OUTPUT ]
   then
      rm $OUTPUT
   fi 

   sqlplus -s / <<EOF > /dev/null
   whenever sqlerror exit failure
   set heading off feedback off  pagesize 9999 linesize 150

   spool $OUTPUT
select '#!/bin/ksh' from dual;

select 'dbv blocksize=8192 file=' || name || ' logfile=$OUTPUT_PATH/dbv_$ORACLE_SID' || file# || '.out'
from v\$datafile
order by file#
/

select 'cat $OUTPUT_PATH/dbv_$ORACLE_SID' || '* > $MERGED' from dual;
select 'rm $OUTPUT_PATH/dbv_$ORACLE_SID'  || '*' from dual;

   spool off

   exit
EOF

    chmod u+x $OUTPUT

    echo "The shell script to verify the Oracle datafiles has been created " $OUTPUT

#    MailIt "DBVerify Complete $ORACLE_SID" $EMPTY_FILE $mailist email

return $?
}

###-------------------------------------------------------------------------------------
function run_sql
{
   USAGE="Usage: run_sql  arg1 (arg1=sql to run) arg2 (arg2=output to this file) arg3 (arg3=ID)"

    if test "$#" -lt 3
    then
        echo $USAGE
        return 1
    fi

    RUNTHISSQL=$1
    OUTPUTHERE=$2
    ID=$3

   # Check if xtrace debugging should be started
    typeset -i DebugLevel
    if [[ $DebugLevel == 9 ]]
    then
       set -o xtrace
    else
       set +o xtrace
    fi 

   #  Check if the SQL you desire to run is already running
   COUNTEM=`ps -ef | grep $RUNTHISSQL | egrep -v grep | egrep -v ksh | egrep -v sh | wc -l`

   if [ $COUNTEM == 0 ]
   then
      sqlplus -s $ID @$RUNTHISSQL > $OUTPUTHERE
   fi 

return $?
}


############################################################
####                              MENU  FUNCTIONS
############################################################

###-------------------------------------------------------------------------------------
function MenuHeader
{
routeto=`cat $SCRIPTS/dynamic/routeto`
tput clear
cat <<EOF
------------------------------------------------------------------------------------------
Run Oracle SQL - runsql_lib.ksh `date "+%x %X"`     DebugLevel: $DebugLevel

  Localhost: `uname -n`    User: $LOGNAME    Report Routed to: $routeto
 ORACLE_SID: $ORACLE_SID
 ORACLE_HOME: $ORACLE_HOME
  
EOF
}


###-------------------------------------------------------------------------------------
function menu
{
typeset -i answer
typeset -i mainstat=0

routeto

while (( mainstat != 99 ))
   do
   MenuHeader
   cat <<EOF

   1.  Reports Menu
   2.  Maintenance Menu

   99. Exit Menu 	999. Route Report

EOF
   echo "   Enter option: \c"

   read answer

   case $answer in
      1  )MenuReports ;;
      2  )MenuMaint ;;
      999  )routeto ;;
    99|x ) return 0;;
      *  ) echo "Try again - press return \c";
           read x;;
   esac
done
}   


####################### Level 1 menu ##########################
function MenuReports
{
typeset -i reportstat=0
typeset -i answer
typeset -l routeto

while (( reportstat != 99 ))
   do
   MenuHeader
   cat <<EOF
       COMMON				     	     PERFORMANCE		     MISCELLANEOUS
   1.  Invalid Objects				16.  Tuning Statistics		31.  Tablespace Mapping
   2.  Tablespace Freespace			17.  Rollback Information	32.  Pinned Objects
   3.  Segments with extents over threshold	18.  Active Rollbacks		33.  Pinnable Objects
   4.  Segments Unable to Get Next Extent	19.  Enqueue Waits		34.  Configuration Information
   5.  Table Reorg Candidates			20.  System Memory (Oracle)	35.  Database Layout
   6.  Index Reorg Candidates			21.  Latch Information		36.  Database Usage
   7.  						22.  Sort Area Usage		37.  Redundent Index Analysis
   8.  						23.  Parse Calls
   9.  						24.  Process I/O
  10.  						25.  Current Database Transactions
  11.  						26.
  12.  						27.
  13.  						28.  
  14.  						29.  
  15.  						30.  

   99. Up a Level	999. Route Report

EOF

   echo "   Enter option: \c"

   read answer

   case $answer in
      1  ) rpt_invalid_objects $routeto ;;
      2  ) rpt_freespace $routeto ;;
      3  ) rpt_extents_over_threshold $routeto ;;
      4  ) rpt_objects_unable_to_get_next_extent $routeto ;;
      5  ) rpt_reorg_table_info $routeto ;;
      6  ) rpt_reorg_index_info $routeto ;;
     16  ) rpt_tuning_statistics $routeto ;;
     17  ) rpt_rollback_info $routeto ;;
     18  ) rpt_active_rollbacks $routeto ;;
     19  ) rpt_enqueue_waits $routeto ;;
     20  ) rpt_system_memory $routeto ;;
     21  ) rpt_latches $routeto ;;
     22  ) rpt_sort_usage $routeto ;;
     23  ) rpt_parse_calls $routeto ;;
     24  ) rpt_process_IO $routeto ;;
     25  ) rpt_current_database_transactions $routeto ;;
     31  ) rpt_tablespace_mapping $routeto ;;
     32  ) rpt_pinned_objects $routeto ;;
     33  ) rpt_pinnable_objects $routeto ;;
     34  ) rpt_configuration_info $routeto ;;
     35  ) rpt_database_layout $routeto ;;
     36  ) rpt_database_usage $routeto ;;
     37  ) rpt_redundent_index_analysis $routeto ;;

     999  ) routeto ;;
    99|x ) return 0;;
      *  ) echo "Try again - press return \c";
           read x;;
   esac
done
}


####################### Level 1 menu ##########################
function MenuMaint
{
typeset -i maintstat=0
typeset -i answer
typeset -l routeto

while (( maintstat != 99 ))
   do
   MenuHeader
   cat <<EOF

   1.  Compile All Invalid Objects


   99. Up a Level	999. Route Report

EOF

   echo "   Enter option: \c"

   read answer

   case $answer in
      1  )compile_invalid_objects_all $routeto ;;
     999  ) routeto ;;
    99|x ) return 0;;
      *  ) echo "Try again - press return \c";
           read x;;
   esac
done
}

echo "SQL Library functions Loaded"

####==============================================================
### Start processes here



