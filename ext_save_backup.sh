#!/bin/ksh

# Script creates a saved backup file with the
# necessary info to save the backup and to
# restore the backup.
#
# Scripts accepts one or three parameters
#
# Required DataBase Name
#
# Optional backup start and end times
#
#      BKP_START="12/18/2019 10:46:35 PM"
#      BKP_END="12/18/2019 10:50:12 PM"
#
#      If dates omitted, script assumes most recent backup
#      and obtains info from view rc_rman_backup_job_details
#
# Example script executions:
#
# ext_save_backup.ksh HEDWQA2
#
# ext_save_backup.ksh HEDWQA2 '12/18/2019 01:22:13 PM' '12/18/2019 01:25:22 PM'
#
# This script was written in support of the following activities:
#  Backup database and logs followed by another log backup

# Change Directory
cd ${HOME}/tls/rman

# Set To Input Parm Count
PARMCNT=${#}

# Check for Input Parameters
if [ ${PARMCNT} -eq 0 ] ; then
   echo
   echo "Input DataBase Not Passed - Script Aborting"
   exit 1
fi

# Check for Input Parameters
if [ ${PARMCNT} -gt 1 ] ; then
 if [ ${PARMCNT} -ne 3 ] ; then
   echo
   echo "Input DataBase, Backup Start and End Date Not Passed - Script Aborting"
   exit 1
 fi
fi

# Set DataBase Name
DBName="$1"

# Upper Case DataBase Name
typeset -u DBName

# Set To Input Backup Dates If Passed
if [ ${PARMCNT} -eq 3 ] ; then
   BKP_START="$2"
   BKP_END="$3"
fi

# Set RMAN Catalog
RCATDB=RCATDEV

# Set Oracle Environment
. ~oracle/.bash_profile > /dev/null 2>&1
export ORAENV_ASK=NO
export ORACLE_SID=${DBName}
. oraenv > oraenv_save_backup_${DBName}.out 2>&1


# Set RMAN Catalog Password
export RCATPASS=`rcatpass`

# Set RMAN Connect String
export RMANCONN="${DBName}/${RCATPASS}"

# Confirm Input Backup Dates If Passed In
if [ ${PARMCNT} -eq 3 ] ; then
   BKP_START_CNT=`sqlplus -s <<EOF
   ${RMANCONN}@${RCATDB}
   whenever sqlerror exit failure
   set pagesize 0 head off feed off
   select count(*)
   from   rc_rman_backup_job_details
   where  input_type = 'DB INCR'
   and    to_char(start_time, 'MM/DD/YYYY HH:MI:SS AM') = '${BKP_START}';
EOF`

   if [ $? -ne 0 ] ; then
      echo
      echo "Error Confirming Backup Start Time - Script Aborting"
      exit 1
   fi
   
   if [ ${BKP_START_CNT} -eq 0 ] ; then
      echo
      echo "Backup Start Time Not Found - Script Aborting"
      exit 1
   fi

   BKP_END_CNT=`sqlplus -s <<EOF
   ${RMANCONN}@${RCATDB}
   whenever sqlerror exit failure
   set pagesize 0 head off feed off
   select count(*)
   from   rc_rman_backup_job_details
   where  input_type = 'DB INCR'
   and    to_char(end_time, 'MM/DD/YYYY HH:MI:SS AM') = '${BKP_END}';
EOF`

   if [ $? -ne 0 ] ; then
      echo
      echo "Error Confirming Backup End Time - Script Aborting"
      exit 1
   fi
   
   if [ ${BKP_END_CNT} -eq 0 ] ; then
      echo
      echo "Backup END Time Not Found - Script Aborting"
      exit 1
   fi

fi

# Get Latest Backup if dates not passed in
if [ ${PARMCNT} -eq 1 ] ; then
   BKP_START=`sqlplus -s <<EOF
   ${RMANCONN}@${RCATDB}
   whenever sqlerror exit failure
   set pagesize 0 head off feed off
   select to_char(start_time, 'MM/DD/YYYY HH:MI:SS AM')
   from   rc_rman_backup_job_details 
   where  input_type = 'DB INCR'
   and    start_time = 
   (select max(start_time) 
    from   rc_rman_backup_job_details 
    where  input_type = 'DB INCR'
    and    status = 'COMPLETED');
EOF`

   if [ $? -ne 0 ] ; then
      echo
      echo "Error Selecting Backup Start Time - Script Aborting"
      exit 1
   fi

   if [ -z "${BKP_START}" ] ; then
      echo
      echo "Backup Start Time Not Found - Script Aborting"
      exit 1
   fi

   BKP_END=`sqlplus -s <<EOF
   ${RMANCONN}@${RCATDB}
   whenever sqlerror exit failure
   set pagesize 0 head off feed off
   select to_char(end_time, 'MM/DD/YYYY HH:MI:SS AM')
   from   rc_rman_backup_job_details 
   where  input_type = 'DB INCR'
   and    end_time = 
   (select max(end_time) 
    from   rc_rman_backup_job_details 
    where  input_type = 'DB INCR'
    and    status = 'COMPLETED');
EOF`

   if [ $? -ne 0 ] ; then
      echo
      echo "Error Selecting Backup End Time - Script Aborting"
      exit 1
   fi

   if [ -z "${BKP_END}" ] ; then
      echo
      echo "Backup End Time Not Found - Script Aborting"
      exit 1
   fi

fi

# Confirm Valid Date
sqlplus -s /nolog << EOF > /dev/null
 whenever sqlerror exit failure
 connect / as sysdba
 select to_date('${BKP_START}', 'MM/DD/YYYY HH:MI:SS AM') from dual;
EOF

# If Not Valid Start Date
if [ $? -ne 0 ] ; then
   echo
   echo "Invalid Backup Start Date Encountered - Script Aborting"
   echo ${BKP_START}
   echo $RC
   exit 1
fi

# Confirm Valid Date
sqlplus -s /nolog << EOF > /dev/null
 whenever sqlerror exit failure
 connect / as sysdba
 select to_date('${BKP_END}', 'MM/DD/YYYY HH:MI:SS AM') from dual;
EOF

# If Not Valid End Date
if [ $? -ne 0 ] ; then
   echo
   echo "Invalid Backup End Date Encountered - Script Aborting"
   echo ${BKP_END}
   exit 1
fi

# Set Output File Name
SAVEBKP_RMAN=${DBName}_sbk_`echo $BKP_START|awk -F' ' '{print $1}'|awk -F/ '{printf "%s%02s%02s", $3,$1,$2}'`_`echo $BKP_START|awk -F' ' '{print $2}'`.rman

# Determine If Saved Backup Script Exists
if [ -f ${SAVEBKP_RMAN} ] ; then
   echo
   echo "Saved Backup File ${SAVEBKP_RMAN} already Exists"
   exit 1
fi

# Confirm Backup Completed Successfully
if [ ${PARMCNT} -eq 3 ] ; then
   BKP_FAIL_CNT=`sqlplus -s <<EOF
   ${RMANCONN}@${RCATDB}
   whenever sqlerror exit failure
   set pagesize 0 head off feed off
   select count(*)
   from   rc_rman_backup_job_details
   where  input_type = 'DB INCR'
   and    to_char(start_time, 'MM/DD/YYYY HH:MI:SS AM') = '${BKP_START}'
   and    status = 'FAILED';
EOF`

   if [ $? -ne 0 ] ; then
      echo
      echo "Error Confirming Backup Completed Successfully - Script Aborting"
      exit 1
   fi

   if [ ${BKP_FAIL_CNT} -gt 0 ] ; then
      echo
      echo "Backup For Specified Start Time Failed - Script Aborting"
      exit 1
   fi
fi

# Get DataBase ID
integer DBID=`sqlplus -s <<EOF
${RMANCONN}@${RCATDB}
set pagesize 0 head off feed off
select dbid
from  rc_database_incarnation
where resetlogs_time =
(select max(resetlogs_time)
 from  rc_database_incarnation
 where resetlogs_time < to_date('${BKP_START}', 'MM/DD/YYYY HH:MI:SS AM'));
EOF`

# Get DataBase Incarnation
integer DBINC_KEY=`sqlplus -s <<EOF
${RMANCONN}@${RCATDB}
set pagesize 0 head off feed off
select dbinc_key
from   rc_database_incarnation
where resetlogs_time =
(select max(resetlogs_time)
 from  rc_database_incarnation
 where resetlogs_time < to_date('${BKP_START}', 'MM/DD/YYYY HH:MI:SS AM'));
EOF`

# Determine if in archivelog mode at time of backup
integer ARCHCNT=`sqlplus -s <<EOF
${RMANCONN}@${RCATDB}
set pagesize 0 head off feed off
select count(*)
from  rc_backup_archivelog_details
where first_time >= to_date('${BKP_START}', 'MM/DD/YYYY HH:MI:SS AM')
and   first_time <= to_date('${BKP_END}', 'MM/DD/YYYY HH:MI:SS AM');
EOF`

# Set Log Mode
if [ ${ARCHCNT} -gt 0 ] ; then
   LOGMODE=ARCHIVELOG
else
   LOGMODE=NOARCHIVELOG
fi


# Build Restore Commands For NOARCHIVELOG mode
if [ ${LOGMODE} = "NOARCHIVELOG" ] ; then
 sqlplus -s /nolog << EOF |tee -a ${SAVEBKP_RMAN}
  connect ${RMANCONN}@${RCATDB}
  set pagesize 0 head off feed off trimspool on line 130
  col bs_key for 999999999990
  col handle for a100

  prompt ##${DBName} Backup Info;
  prompt #Backup Start Time - ${BKP_START};
  prompt #Backup End Time - ${BKP_END};

  prompt ###......................................................................
  select '#Restore DataBase Time - '||
         to_char (BP.completion_time ,'YYYY-MM-DD HH24:MI:SS')
  from   RC_BACKUP_PIECE BP,
         RC_BACKUP_CONTROLFILE BC
  where  BP.BS_KEY = BC.BS_KEY
  and    BP.start_time >= to_date('${BKP_START}', 'MM/DD/YYYY HH:MI:SS AM')
  and    BP.completion_time <= to_date('${BKP_END}', 'MM/DD/YYYY HH:MI:SS AM')
  and    BC.completion_time =
         (select max( bc1.completion_time)
          from   RC_BACKUP_CONTROLFILE BC1
          where  bc1.completion_time <=to_date('${BKP_END}', 'MM/DD/YYYY HH:MI:SS AM'));

  prompt ###......................................................................
  prompt ###Backup Set Keys and Pieces Created during this backup
  select '#'||bs_key||' - '||handle
  from   RC_BACKUP_PIECE
  where  start_time >= to_date('${BKP_START}', 'MM/DD/YYYY HH:MI:SS AM')
  and    completion_time <= to_date('${BKP_END}', 'MM/DD/YYYY HH:MI:SS AM')
  order by bs_key;
  prompt ###End Backup Set Pieces

  prompt ###......................................................................
  prompt ###Tags Created during this backup
  select DISTINCT '#'||TAG||' - Data Files'
  from   RC_BACKUP_PIECE
  where  start_time >= to_date('${BKP_START}', 'MM/DD/YYYY HH:MI:SS AM')
  and    completion_time <= to_date('${BKP_END}', 'MM/DD/YYYY HH:MI:SS AM')
  and    handle not like '%c-%'
  union
  select DISTINCT '#'||TAG||' - Control File'
  from   RC_BACKUP_PIECE
  where  start_time >= to_date('${BKP_START}', 'MM/DD/YYYY HH:MI:SS AM')
  and    completion_time <= to_date('${BKP_END}', 'MM/DD/YYYY HH:MI:SS AM')
  and    handle like '%c-%'
  union
  select DISTINCT '#'||TAG||' - Control File'
  from   RC_BACKUP_PIECE BP,
         RC_BACKUP_CONTROLFILE BC
  where  start_time >= to_date('${BKP_START}', 'MM/DD/YYYY HH:MI:SS AM')
  and    BP.completion_time <= to_date('${BKP_END}', 'MM/DD/YYYY HH:MI:SS AM')
  and    BP.BS_KEY = BC.BS_KEY
  and    BC.completion_time =
        (select max( bc1.completion_time)
         from   RC_BACKUP_CONTROLFILE BC1
         where  BC1.completion_time <= to_date('${BKP_END}', 'MM/DD/YYYY HH:MI:SS AM'));
  prompt ##End Tags Created

  prompt ###......................................................................
  prompt ##Keep DataBase Backup
  select distinct 'CHANGE BACKUPSET ' || BS_KEY ||
         ' KEEP FOREVER NOLOGS;'
  from   RC_BACKUP_PIECE
  where  start_time >= to_date('${BKP_START}', 'MM/DD/YYYY HH:MI:SS AM')
  and    completion_time <= to_date('${BKP_END}', 'MM/DD/YYYY HH:MI:SS AM')
  order by 1;
  prompt ##End Keep DataBase Backup

  prompt ###......................................................................
  prompt ##Delete DataBase Backup
  select distinct '#DELETE NOPROMPT BACKUPSET ' || BS_KEY ||
         ';'
  from   RC_BACKUP_PIECE
  where  start_time >= to_date('${BKP_START}', 'MM/DD/YYYY HH:MI:SS AM')
  and    completion_time <= to_date('${BKP_END}', 'MM/DD/YYYY HH:MI:SS AM')
  order by 1;
  prompt ##End Delete DataBase Backup

  prompt ###......................................................................
  prompt ##Restore DataBase
  prompt #connect target /
  prompt #connect catalog ${DBName}/xyz@${RCATDB}
  prompt #startup force nomount;;

  prompt #set DBID=${DBID}

  prompt #reset database to incarnation ${DBINC_KEY};;

  select '#restore controlfile from ''' ||  handle || ''';'
  from   RC_BACKUP_PIECE BP,
         RC_BACKUP_CONTROLFILE BC
  where  BP.BS_KEY = BC.BS_KEY
  and    BP.start_time >= to_date('${BKP_START}', 'MM/DD/YYYY HH:MI:SS AM')
  and    BP.completion_time <= to_date('${BKP_END}', 'MM/DD/YYYY HH:MI:SS AM')
  and    BC.completion_time =
         (select max( bc1.completion_time)
          from   RC_BACKUP_CONTROLFILE BC1
          where  bc1.completion_time <= to_date('${BKP_END}', 'MM/DD/YY HH:MI:SS AM'));

  prompt #alter database mount;;

  prompt #run{;

  select distinct '#restore database from TAG='||TAG||';'
  from   RC_BACKUP_PIECE
  where  start_time >= to_date('${BKP_START}', 'MM/DD/YYYY HH:MI:SS AM')
  and    completion_time <= to_date('${BKP_END}', 'MM/DD/YYYY HH:MI:SS AM')
  and    handle not like '%c-%';

  prompt #recover database noredo;;
  prompt #};
  prompt #alter database open resetlogs;;
  prompt ##End Restore DataBase

EOF

fi



# Build Restore Commands For ARCHIVELOG mode
if [ ${LOGMODE} = "ARCHIVELOG" ] ; then
 sqlplus -s /nolog << EOF |tee -a ${SAVEBKP_RMAN}
     connect ${RMANCONN}@${RCATDB}
     set pagesize 0 head off feed off trimspool on line 130
     col bs_key for 999999999990
     col handle for a100

     prompt ##${DBName} Backup Info;
     prompt #Backup Start Time - ${BKP_START};
     prompt #Backup End Time - ${BKP_END};

     select '#DataBase Restore Time - '||
            to_char (BP.completion_time ,'YYYY-MM-DD HH24:MI:SS')
     from   RC_BACKUP_PIECE BP,
            RC_BACKUP_CONTROLFILE BC
     where  BP.BS_KEY = BC.BS_KEY
     and    BP.start_time >= to_date('${BKP_START}', 'MM/DD/YYYY HH:MI:SS AM')
     and    BP.completion_time <= to_date('${BKP_END}', 'MM/DD/YYYY HH:MI:SS AM')
     and    BC.completion_time =
            (select max( bc1.completion_time)
             from   RC_BACKUP_CONTROLFILE BC1
             where  BC1.completion_time <= to_date('${BKP_END}', 'MM/DD/YYYY HH:MI:SS AM'));

     select '#Log Sequence Number = ' || trim(max(sequence#)) || ';'
     from   RC_BACKUP_PIECE bp,
            RC_BACKUP_REDOLOG br
     where  bp.bs_key = br.bs_key
     and    start_time >= to_date('${BKP_START}', 'MM/DD/YYYY HH:MI:SS AM')
     and    bp.completion_time <= to_date('${BKP_END}', 'MM/DD/YYYY HH:MI:SS AM')
     and    start_time =
     (select max(start_time)
      from   RC_BACKUP_PIECE bp2,
             RC_BACKUP_REDOLOG br2
      where  bp2.bs_key = br2.bs_key
      and    bp2.start_time >= to_date('${BKP_START}', 'MM/DD/YYYY HH:MI:SS AM')
      and    bp2.completion_time <= to_date('${BKP_END}', 'MM/DD/YYYY HH:MI:SS AM')
      and    handle not like '%c-%'
     );

     prompt ###......................................................................
     prompt ###Backup Set Keys and Pieces Created during this backup
     select '#'||bs_key||' - '||handle
     from   RC_BACKUP_PIECE
     where  start_time >= to_date('${BKP_START}', 'MM/DD/YYYY HH:MI:SS AM')
     and    completion_time <= to_date('${BKP_END}', 'MM/DD/YYYY HH:MI:SS AM')
     order by bs_key;
     prompt ###End Backup Set Pieces

     prompt ###......................................................................
     prompt ###Tags Created during this backup
     select DISTINCT '#'||TAG||' - Data Files'
     from   RC_BACKUP_PIECE
     where  start_time >= to_date('${BKP_START}', 'MM/DD/YYYY HH:MI:SS AM')
     and    completion_time <= to_date('${BKP_END}', 'MM/DD/YYYY HH:MI:SS AM')
     and    handle not like '%c-%'
     union
     select DISTINCT '#'||TAG||' - Control File'
     from   RC_BACKUP_PIECE
     where  start_time >= to_date('${BKP_START}', 'MM/DD/YYYY HH:MI:SS AM')
     and    completion_time <= to_date('${BKP_END}', 'MM/DD/YYYY HH:MI:SS AM')
     and    handle like '%c-%'
     union
     select DISTINCT '#'||TAG||' - Control File'
     from   RC_BACKUP_PIECE BP,
            RC_BACKUP_CONTROLFILE BC
     where  start_time >= to_date('${BKP_START}', 'MM/DD/YYYY HH:MI:SS AM')
     and    BP.completion_time <= to_date('${BKP_END}', 'MM/DD/YYYY HH:MI:SS AM')
     and    BP.BS_KEY = BC.BS_KEY
     and    BC.completion_time =
           (select max( bc1.completion_time)
            from   RC_BACKUP_CONTROLFILE BC1
            where  BC1.completion_time <= to_date('${BKP_END}', 'MM/DD/YYYY HH:MI:SS AM'));
     prompt ##End Tags Created
     prompt ###......................................................................
prompt ## Use this time to recover to the point when this backup was taken
     select distinct '#SET UNTIL TIME "TO_DATE(''' || to_char(completion_time, 'MM/DD/YYYY HH24:MI:SS') ||''', ''MM/DD/YYYY HH24:MI:SS'')";'
     from   RC_BACKUP_REDOLOG BR
     where  BR.completion_time > to_date('${BKP_START}', 'MM/DD/YYYY HH:MI:SS AM')
     and    BR.completion_time < to_date('${BKP_END}', 'MM/DD/YYYY HH:MI:SS AM')
     and    BR.completion_time =
     (select max(BR1.completion_time)
      from   RC_BACKUP_REDOLOG BR1
      where  BR1.completion_time > to_date('${BKP_START}', 'MM/DD/YYYY HH:MI:SS AM')
      and    BR1.completion_time < to_date('${BKP_END}', 'MM/DD/YYYY HH:MI:SS AM'));
     prompt ##......................................................................
     prompt ##Keep DataBase Backup
     select distinct 'CHANGE BACKUPSET ' || BS_KEY ||
            ' KEEP FOREVER;'
     from   RC_BACKUP_PIECE
     where  start_time >= to_date('${BKP_START}', 'MM/DD/YYYY HH:MI:SS AM')
     and    completion_time <= to_date('${BKP_END}', 'MM/DD/YYYY HH:MI:SS AM')
     order by  1;
     prompt ##End Keep DataBase Backup

     prompt ###......................................................................
     prompt ##Delete DataBase Backup
     select distinct '#DELETE NOPROMPT BACKUPSET ' || BS_KEY ||
            ';'
     from   RC_BACKUP_PIECE
     where  start_time >= to_date('${BKP_START}', 'MM/DD/YYYY HH:MI:SS AM')
     and    completion_time <= to_date('${BKP_END}', 'MM/DD/YYYY HH:MI:SS AM')
     order by  1;
     prompt ##End Delete DataBase Backup

     prompt ###......................................................................
     prompt ##Restore DataBase
     prompt #connect target /
     prompt #connect catalog ${DBName}/xyz@${RCATDB}
     prompt #startup force nomount;;

     prompt #set DBID=${DBID}

     prompt #reset database to incarnation ${DBINC_KEY};;

     select '#restore controlfile from ''' ||  handle || ''';'
     from   RC_BACKUP_PIECE BP,
            RC_BACKUP_CONTROLFILE BC
     where  BP.BS_KEY = BC.BS_KEY
     and    BP.start_time >= to_date('${BKP_START}', 'MM/DD/YYYY HH:MI:SS AM')
     and    BP.completion_time <= to_date('${BKP_END}', 'MM/DD/YYYY HH:MI:SS AM')
     and    BC.completion_time =
           (select max( bc1.completion_time)
            from   RC_BACKUP_CONTROLFILE BC1
            where  bc1.completion_time <= to_date('${BKP_END}', 'MM/DD/YY HH:MI:SS AM'));

     prompt #alter database mount;;

     prompt #run{;

     select '#restore database until sequence ' || trim(max(sequence#)) || ';'
     from   RC_BACKUP_PIECE bp,
            RC_BACKUP_REDOLOG br
     where  bp.bs_key = br.bs_key
     and    bp.start_time >= to_date('${BKP_START}', 'MM/DD/YYYY HH:MI:SS AM')
     and    bp.completion_time <= to_date('${BKP_END}', 'MM/DD/YYYY HH:MI:SS AM')
     and    bp.start_time =
     (select max(start_time)
      from   RC_BACKUP_PIECE bp2,
             RC_BACKUP_REDOLOG br2
      where  bp2.bs_key = br2.bs_key
      and    bp2.start_time >= to_date('${BKP_START}', 'MM/DD/YYYY HH:MI:SS AM')
      and    bp2.completion_time <= to_date('${BKP_END}', 'MM/DD/YYYY HH:MI:SS AM')
      and    handle not like '%c-%'
     );

     select '#recover database until sequence ' || trim(max(sequence#)) || ';'
     from   RC_BACKUP_PIECE bp,
            RC_BACKUP_REDOLOG br
     where  bp.bs_key = br.bs_key
     and    bp.start_time >= to_date('${BKP_START}', 'MM/DD/YYYY HH:MI:SS AM')
     and    bp.completion_time <= to_date('${BKP_END}', 'MM/DD/YYYY HH:MI:SS AM')
     and    start_time =
     (select max(start_time)
      from   RC_BACKUP_PIECE bp2,
             RC_BACKUP_REDOLOG br2
      where  bp2.bs_key = br2.bs_key
      and    bp2.start_time >= to_date('${BKP_START}', 'MM/DD/YYYY HH:MI:SS AM')
      and    bp2.completion_time <= to_date('${BKP_END}', 'MM/DD/YYYY HH:MI:SS AM')
      and    handle not like '%c-%'
     );

     prompt #};
     prompt #alter database open resetlogs;;
     prompt ##End Restore DataBase

EOF

fi

# Change File Permissions
chmod 600 ${SAVEBKP_RMAN}

