#!/bin/ksh

get_mountpoints_for_tablespace()
{
   while read tsname datafile
   do
     filedir=`dirname $datafile`
     print -n "$tsname\t"
     df -k $filedir | tail -1 | awk '{printf "%s\t%d\t%d\t%d\n", $7, $2, $3, $4}'
   done < $TSLIST_FILE
}

list_oracle_mountpoint_usage()
{
   df -m `list_nonstatic_directories` | \
      awk -v inst=$ORACLE_SID -v sdate=$RUN_DATE -v host=$HOST 'NR>1 {printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\n", host, inst, sdate, $7, $2, $3, $4 }' | \
         tr -d '%' | sort | uniq
}

list_tablespace_usage()
{
   sqlplus -S /nolog <<-EOF | awk -v host=$HOST 'NF>1 {printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\n",host, $2, $3, $4, $5, $6, $8}'
	set pagesize 0
	set heading off
	set trimspool on
	set feedback off
	set verify off
	set linesize 1024
	whenever sqlerror exit failure
	connect / as sysdba
	select '===', 
               sys_context('USERENV', 'DB_NAME') as instance,
               '${RUN_DATE}' as sample_date,
               b.tablespace_name,
               case when sum(decode(autoextensible, 'YES', 1, 0)) > 0 then 'YES' else 'NO' end as AUTOEXTESIBLE,
               sum(b.bytes)/1024/1024 as Size_MBytes,
               nvl(sum(a.bytes),0)/1024/1024 as Free_MBytes,
               (sum(b.bytes) - nvl(sum(a.bytes),0))/1024/1024 as Used_MBytes,
               100.0 - 100.0*nvl(sum(a.bytes),0)/sum(b.bytes) as PCT_Used
	  from dba_data_files b,
     		(select file_id, sum(bytes) as bytes
        	   from dba_free_space
                 group by file_id) a
 	  where a.file_id (+) = b.file_id
        group by b.tablespace_name
	union all
	select '===', 
               sys_context('USERENV', 'DB_NAME') as instance,
               '${RUN_DATE}' as sample_date,
               tablespace_name,
               case when sum(decode(autoextensible, 'YES', 1, 0)) > 0 then 'YES' else 'NO' end as AUTOEXTESIBLE,
               sum(b.bytes)/1024/1024 as Size_MBytes,
               sum(a.bytes_free)/1024/1024 as Free_MBytes,
               sum(a.bytes_used)/1024/1024 as Used_MBytes,
               100.0*sum(a.bytes_used)/sum(b.bytes) as PCT_Used
	  from dba_temp_files b,
     	       (select file_id, sum(bytes_used) as bytes_used,
                       sum(bytes_free) as bytes_free
        	  from V\$TEMP_SPACE_HEADER
      		group by file_id) a
	  where a.file_id (+) = b.file_id
	group by b.tablespace_name
	order by 1;
	EOF
#   ERR=$?
#   if [ $ERR -ne 0 ]
#   then
#      error_exit "sqlplus failed with $ERR"
#   fi
}

list_nonstatic_directories()
{
   sqlplus -S /nolog <<-EOF | grep '===' > $TMP_DIRLIST
	set pagesize 0
	set heading off
	set trimspool on
	set feedback off
	set linesize 1024
	whenever sqlerror exit failure
	connect / as sysdba
	select '===', translate(file_name, chr(10), '_')
          from dba_data_files
         where autoextensible = 'YES'
	union all
	select '===', translate(file_name, chr(10), '_')
	  from dba_temp_files
         where autoextensible = 'YES'
	union all
	select '===', substr(value, instr(value, '/'))
	  from v\$parameter
	 where (lower(name) in (
				'utl_file_dir',
				'background_dump_dest',
				'user_dump_dest',
				'log_archive_dest')
		    or lower(name) like 'log^_archive^_dest^__' escape '^'
               )
               and value is not null;
	EOF
   ERR=$?
   if [ $ERR -ne 0 ]
   then
      error_exit "sqlplus failed with $ERR"
   fi

   while read dummy d
   do
      dirname $d
   done < $TMP_DIRLIST | sort | uniq
}

gather_spaceinfo()
{
   #get_mountpoints_for_tablespace 
   list_tablespace_usage > $TSUSAGE
   list_oracle_mountpoint_usage > $MPUSAGE
}

load_tablespace_usage()
{
   sqlldr userid=\"$REPOSITORY_USER@$REPOSITORY\" data=$TSUSAGE control=$TSUSAGE_CONTROL \
	errors=0 bad=$TSUSAGE_BAD log=$TSUSAGE_LOG <<-EOF
	$REPOSITORY_PW
	EOF
}

load_mountpoint_usage()
{
   sqlldr userid=\"$REPOSITORY_USER@$REPOSITORY\" data=$MPUSAGE control=$MPUSAGE_CONTROL \
	errors=0 bad=$MPUSAGE_BAD log=$MPUSAGE_LOG <<-EOF
	$REPOSITORY_PW
	EOF
}

load_latest_sample_table()
{
   sqlplus /nolog <<-EOF
	whenever sqlerror exit failure
	connect $REPOSITORY_USER/$REPOSITORY_PW@$REPOSITORY
	delete from ae_spaceinfo_latest l 
	 where l.host = '${HOST}'
	   and l.db_name='${ORACLE_SID}';

	insert into ae_spaceinfo_latest (host, db_name, sample_date)
	values ('${HOST}', '${ORACLE_SID}', to_date('${SAMPLE_DATE}', 'YYYY-MM-DD HH24:MI:SS'));
	commit;
	EOF
}


load_to_repository()
{
   load_latest_sample_table
   load_tablespace_usage
   load_mountpoint_usage
}

error_exit()
{
   print $1
   exit 1
}

cleanup()
{
   rm -f $TMP_DIRLIST
}

usage()
{
    print "gather_spaceinfo.sh"
}


########################### Main ##########################################

JOB=`basename $0`
PATH=$PATH:/usr/local/bin
RUN_DATE=`date +"%Y-%m-%d_%H:%M:%S"`
TMPDIR=/tmp
TMP_DIRLIST=$TMPDIR/${JOB}_DIRLIST.$$
SCRIPTHOME=/ivrprod/orabin/aetna/scripts/monitor/space
STATSDIR=$SCRIPTHOME/data
LOGDIR=$SCRIPTHOME/logs
REPOSITORY_USER=aedba
REPOSITORY_PW=aedba
REPOSITORY='(DESCRIPTION=(ADDRESS_LIST=(ADDRESS=(PROTOCOL=TCP)(HOST=floradev)(PORT=1550)))(CONNECT_DATA=(SERVICE_NAME=DBATST.WORLD)))'
SAMPLE_DATE=`date +"%Y-%m-%d %H:%M:%S"`
HOST=`hostname`

TSUSAGE=$STATSDIR/$INSTANCE.TSUSAGE.$RUN_DATE.dat
TSUSAGE=$STATSDIR/$INSTANCE.TSUSAGE.$RUN_DATE.dat
MPUSAGE=$STATSDIR/$INSTANCE.MPUSAGE.$RUN_DATE.dat
TSUSAGE_BAD=$LOGDIR/tsusage.bad
TSUSAGE_CONTROL=$SCRIPTHOME/tsusage.ctl
TSUSAGE_LOG=$LOGDIR/tsusage.log
MPUSAGE_BAD=$LOGDIR/mpusage.bad
MPUSAGE_CONTROL=$SCRIPTHOME/mpusage.ctl
MPUSAGE_LOG=$LOGDIR/mpusage.log

export ORAENV_ASK=NO

if [ -z "$1" ]
then
   for i in `awk -F":" '!/^#.*/ {if ($3 == "Y") {print $1}}' /etc/oratab`
   do

      export ORACLE_SID=$i

      if [ -z "$ORACLE_SID" ]
      then
         echo "Error:  ORACLE_SID is NULL"
         exit 1
      fi

      . oraenv
      gather_spaceinfo
      load_to_repository
      cleanup
   done
else
   export ORACLE_SID=$1
   if [ -z "$ORACLE_SID" ]
   then
      echo "Error:  ORACLE_SID is NULL"
      exit 1
   fi

   . oraenv
   gather_spaceinfo
   load_to_repository
   cleanup
fi


