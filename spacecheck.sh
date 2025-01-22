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

list_all_oracle_directories()
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
	union all
	select '===', translate(file_name, chr(10), '_')
	  from dba_temp_files
	union all
	select '===', member
	  from v\$logfile
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

list_oracle_mountpoint_usage()
{
   df -m `list_nonstatic_directories` | \
      awk 'NR>1 {printf "%s\t%s\t%s\t%s\n", $7, $2, $3, $4 }' | \
         tr -d '%' | sort | uniq
}

list_static_tablespace_usage()
{
   sqlplus -S /nolog <<-EOF | awk '{printf "%s\t%s\t%s\t%s\n", $2, $3, $4, $5}'
	set pagesize 0
	set heading off
	set trimspool on
	set feedback off
	set linesize 1024
	whenever sqlerror exit failure
	connect / as sysdba
	select '===', b.tablespace_name,
               sum(b.bytes)/1024/1024 as Size_MBytes,
               nvl(sum(a.bytes),0)/1024/1024 as Free_MBytes,
               --(sum(b.bytes) - nvl(sum(a.bytes),0))/1024/1024 as Used_MBytes,
               100.0 - 100.0*nvl(sum(a.bytes),0)/sum(b.bytes) as PCT_Used
	  from dba_data_files b,
     		(select file_id, sum(bytes) as bytes
        	   from dba_free_space
                 group by file_id) a
 	  where a.file_id (+) = b.file_id
 	    and not exists  (select 1 
		               from dba_data_files df2 
		    	      where b.tablespace_name = df2.tablespace_name
			        and df2.autoextensible = 'YES'
		  	    )
        group by b.tablespace_name
	union all
	select '===', tablespace_name,
               sum(b.bytes)/1024/1024 as Size_MBytes,
               sum(a.bytes_free)/1024/1024 as Free_MBytes,
               --sum(a.bytes_used)/1024/1024 as Used_MBytes,
               100.0*sum(a.bytes_used)/sum(b.bytes) as PCT_Used
	  from dba_temp_files b,
     	       (select file_id, sum(bytes_used) as bytes_used,
                       sum(bytes_free) as bytes_free
        	  from V\$TEMP_SPACE_HEADER
      		group by file_id) a
	  where a.file_id (+) = b.file_id
            and not exists  (select 1 
			      from dba_temp_files tf2 
		    	     where b.tablespace_name = tf2.tablespace_name
			       and tf2.autoextensible = 'YES'
		  	   )
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

filter_rows()
{
   FILTER_LEVEL=$1
   while read name size free pct
   do
      if [ ! -z "$pct" ]
      then
         if [ $pct -ge $FILTER_LEVEL ]
         then
            print "$name\t$size\t$free\t$pct"
         fi
      fi
   done
}

list_alert_tablespaces()
{
   list_static_tablespace_usage > $TMP_ALERT_TS_LIST
   cat $TMP_ALERT_TS_LIST | filter_rows $ALERT_THRESHOLD
}

list_alert_mountpoints()
{
   list_oracle_mountpoint_usage > $TMP_ALERT_MP_LIST
   cat $TMP_ALERT_MP_LIST | filter_rows $ALERT_THRESHOLD
}

print_html_report_header()
{
   TITLE=$1
   cat <<-EOF
	<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
	<html>
	<head>
	<title>$TITLE</title>
	</head>
	<body>
	EOF
}

print_html_report_footer()
{
   cat <<-EOF
	</body>
	</html>
	EOF
}

print_html_report_body_contents()
{
   cat <<-EOF
	<h1>Potential Space Concerns for $INSTANCE</h1>
	<br>
	EOF

   # Static Tablespaces Over N Pct
   cat <<-EOF
	<h2>Static Tablespaces With Utilization Over $ALERT_THRESHOLD %</h2>
	<p>
	These are tablespaces that have no autoallocate datafiles that
	have utilizations over the specified threshold.
	</p>
	<table border=1>
	<tr>
		<th>TS Name</th>
		<th>TS Size(MB)</th>
		<th>Free(MB)</th>
		<th>Pct Used(%)</th>
	</tr>
	EOF

	list_alert_tablespaces | \
	while read name size free pct
	do
		print "<tr><td>$name</td><td>$size</td><td>$free</td><td>$pct</td></tr>"
	done
   
   cat <<-EOF
	</table>
	<br>
	EOF
  
   # Dynamic Filesystem Over N Pct
   cat <<-EOF
	<h2>Dynamic Mount Points With Utilization Over $ALERT_THRESHOLD %</h2>
	<p>
	These are mountpoints that have non-static Oracle file allocations on them.  
	This would include archivelogs, autoallocate data/temp files, alert logs, and
	trace files.
	</p>
	<table border=1>
	<tr>
		<th>Mount Point</th>
		<th>Size(MB)</th>
		<th>Free(MB)</th>
		<th>Pct Used(%)</th>
	</tr>
	EOF

	list_alert_mountpoints  | \
	while read name size free pct
	do
		print "<tr><td>$name</td><td>$size</td><td>$free</td><td>$pct</td></tr>"
	done
   
   cat <<-EOF
	</table>
	<br>
	EOF
}


print_html_report()
{
   print_html_report_header "Special Report"
   print_html_report_body_contents
   print_html_report_footer
}

print_email_header()
{
   TS_COUNT=`cat $TMP_ALERT_TS_LIST | filter_rows $ALERT_THRESHOLD | wc -l`
   MP_COUNT=`cat $TMP_ALERT_MP_LIST | filter_rows $ALERT_THRESHOLD | wc -l`
   if [ $TS_COUNT -ne  0 -o $MP_COUNT -ne 0 ]
   then
      SUBJECT="ALERT: spacecheck for $INSTANCE"
   else
      SUBJECT="OK: spacecheck for $INSTANCE"
   fi

   cat <<-EOF
	Subject: $SUBJECT
	Content-type: text/html
	EOF
}

error_exit()
{
   print $1
   exit 1
}

cleanup()
{
   rm -f $TMP_DIRLIST
   rm -f $TMP_REPORT
   rm -f $TMP_ALERT_TS_LIST
   rm -f $TMP_ALERT_MP_LIST
}

usage()
{
    print "spacecheck.sh <SID> <recipient e-mail>"
    print "Note: If the word "all" is specified for <recipient e-mail> then "
    print "      the report will go to the default distribution list."
}


########################### Main ##########################################

JOB=`basename $0`
PATH=$PATH:/usr/local/bin

TMPDIR=/tmp
TMP_DIRLIST=$TMPDIR/${JOB}_DIRLIST.$$
TMP_ALERT_TS_LIST=$TMPDIR/${JOB}_TSLIST.$$
TMP_ALERT_MP_LIST=$TMPDIR/${JOB}_MPLIST.$$
TMP_REPORT=$TMPDIR/${JOB}_REPORT.$$

# Alert threshold
ALERT_THRESHOLD=80

#EVERYONE="WeichelJM@aetna.com KhersonskyR2@aetna.com SkinnerT@aetna.com KrawetzkyPJ@aetna.com aetna-oracle@inventa.com"
EVERYONE="bermanE@Aetna.com"

INSTANCE=$1
RECIPIENT=$2

if [ -z "$INSTANCE" ]
then
   usage
   error_exit "Oracle SID not specified"
fi

if [ -z "$RECIPIENT" ]
then
   usage
   error_exit "Recipient e-mail not specified"
elif [ "$RECIPIENT" = "all" ]
then
   RECIPIENT=$EVERYONE
fi

export ORAENV_ASK=NO
export ORACLE_SID=$INSTANCE

. oraenv
print_html_report > $TMP_REPORT
print_email_header | cat  - $TMP_REPORT | sendmail $RECIPIENT

cleanup
