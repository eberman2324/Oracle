#!/bin/ksh93
###
### Name: prompt_for_param
### Desc: Prompts the user to enter a parameter
###
prompt_for_param()
{
   typeset param=$1
   typeset pval
   print -u2 -n "Enter a value for $param: "
   read pval
   echo $pval
}

###
### Name: get_param
### Desc: Gets config parameters out of config file
###
get_param()
{
   typeset param=$1
   typeset pval
   pval=`awk -F'[ \t]*=[ \t]*' -v PARAM=$param '!/^#/ && $1==PARAM {print $2}' $CONFIG_FILE`

   if [ "$pval" = "PROMPT" ]
   then
      print -u2 -n "Enter a value for $param: "
      read pval
   fi
   echo $pval
}

###
### Name: get_multi_param_csv_list
### Desc: Gets config parameters out of config file
###
get_multi_param_csv_list()
{
   typeset PARAM=$1
   typeset first=Y

   for p in `awk -F'[ \t]*=[ \t]*' -v PARAM=$PARAM '!/^#/ && $1==PARAM {print $2}' $CONFIG_FILE`
   do
      if [ "$first" = "Y" ]
      then
         first=N
      else
         print -n ','
      fi
      print -n "'${p}'"
   done
}

get_dp_dir()
{
   sqlplus -S -L "/ as sysdba" <<-EOF
	whenever sqlerror exit failure
	set heading off
	set linesize 2048
	set feedback off
	set pagesize 0
	select directory_path from dba_directories where directory_name='DATA_PUMP_DIR';
	exit
	EOF
   if [ $? -ne 0 ]
   then
      return 1
   fi
   return 0
}

log_message()
{
   typeset MESSAGEDATE=`date +"%Y-%m-%d %H:%M:%S :"`
   if [ -z "$LOG_TO_TERMINAL" ]
   then
      print -n "$MESSAGEDATE" >> $LOGFILE
      print "$1" >> $LOGFILE
   else
      print -n "$MESSAGEDATE"
      print "$1"
      print -n "$MESSAGEDATE" >> $LOGFILE
      print "$1" >> $LOGFILE
   fi
}

run_sql_on_standby()
{ 
   typeset sqlfile=${1}
   typeset spoolfile=${2}

   if [ ! -f $sqlfile ]
   then
      log_message "SQL File $sqlfile does not exist"
      return 1
   fi

   # Note, if the 2nd arg isn't passed, that's OK, spoolfile will be null
   # and the command to sqlplus will just be "spool"
   sqlplus -S /nolog 2>&1 > $TEMPFILE <<-EOF 
	set linesize 1024
	set trimspool on
	set echo on
	set pagesize 1024
	whenever sqlerror exit failure
	connect / as sysdba
	spool ${spoolfile}
	@${sqlfile}
	exit
	EOF
   ERR=$?

   if [ $ERR -ne 0 ]
   then
      log_message "Error running sql on standby: $sqlfile.  See $TEMPFILE"
      return 1
   fi

   ERR=`check_for_sql_errors $TEMPFILE`
   if [ $ERR -ne 0 ]
   then
      log_message "Error running sql on standby: $sqlfile.  See $TEMPFILE"
      return 2
   fi
}

run_sql_on_primary()
{ 
   typeset run_target_connstring=`get_param ${PRIMARY_INSTANCE}_USERNAME_PW`@${PRIMARY_INSTANCE}
   typeset sqlfile=${1}
   typeset spoolfile=${2}

   if [ ! -f $sqlfile ]
   then
      log_message "SQL File $sqlfile does not exist"
      return 1
   fi

   # Note, if the 2nd arg isn't passed, that's OK, spoolfile will be null
   # and the command to sqlplus will just be "spool"
   sqlplus -S /nolog 2>&1 > $TEMPFILE <<-EOF 
	set linesize 1024
	set trimspool on
	set echo on
	set pagesize 1024
	whenever sqlerror exit failure
	connect ${run_target_connstring}
	spool ${spoolfile}
	@${sqlfile}
	exit
	EOF
   ERR=$?

   if [ $ERR -ne 0 ]
   then
      log_message "Error running sql $sqlfile.  See $TEMPFILE"
      return 1
   fi

   ERR=`check_for_sql_errors $TEMPFILE`
   if [ $ERR -ne 0 ]
   then
      log_message "Error running sql $sqlfile.  See $TEMPFILE"
      return 2
   fi
}

check_primary()
{
   log_message "Check primary"
   run_sql_on_primary $SQLSCRIPTS/check_primary.sql
   if [ $? -ne 0 ]
   then
      log_message "Error in check_primary"
      return 1
   fi
}

check_standby()
{
   log_message "Check Standby"
   run_sql_on_standby $SQLSCRIPTS/check_standby.sql
   if [ $? -ne 0 ]
   then
      log_message "Error in check_standby"
      return 1
   fi
}

save_logins()
{
   log_message "Save Logins"
   run_sql_on_standby $SQLSCRIPTS/reverse_users.sql $TEMPDIR/saved_logins.sql
   ERR=$?
   
   if [ $ERR -ne 0 ]
   then
      log_message "Error $ERR from run_sql in save_logins"
      return 1
   fi
}

save_directories()
{
   log_message "Save Directories"
   run_sql_on_standby $SQLSCRIPTS/reverse_dirs.sql $TEMPDIR/saved_dirs.sql
   ERR=$?
   
   if [ $ERR -ne 0 ]
   then
      log_message "Error $ERR from run_sql in save_directories"
      return 1
   fi
}

export_local_data()
{
   typeset dp_dir=`get_dp_dir`
   if [ ! -d "$dp_dir" ]
   then
      log_message "DATA_PUMP_DIR $dp_dir not found"
      return 1
   fi

   log_message "Save Local Data"
   if [ -f "$dp_dir/$LOCAL_DATA_EXP" ]
   then
      log_message "Saving previous dump to $dp_dir/$LOCAL_DATA_EXP.1"
      rm -f $dp_dir/$LOCAL_DATA_EXP.prev 2> /dev/null
      rm -f $dp_dir/$LOCAL_DATA_EXP.exp.log.prev 2> /dev/null
      mv $dp_dir/$LOCAL_DATA_EXP $dp_dir/$LOCAL_DATA_EXP.prev
      mv $dp_dir/$LOCAL_DATA_EXP.exp.log $dp_dir/$LOCAL_DATA_EXP.exp.log.prev
   fi
   
   export ORACLE_SID=$STANDBY_INSTANCE
   expdp '"/ as sysdba"' parfile=$EXP_LOCAL_DATA_PAR logfile=$LOCAL_DATA_EXP.exp.log dumpfile=$LOCAL_DATA_EXP 2>&1 >> $LOGFILE
   ERR=$?
   if [ $ERR -ne 0 ]
   then
      log_message "Error exporting local data.  See $LOCAL_DATA_EXP.exp.log"
      return 2
   fi

   ERR=`check_for_sql_errors $LOCAL_DATA_EXP.exp.log`
   if [ $ERR -ne 0 ]
   then
      log_message "Errors found in expdp log.  See $LOCAL_DATA_EXP.exp.log"
      return 3
   fi

}

restart_standby()
{
   log_message "Restart standby"
     sqlplus / as sysdba 2>&1 > $TEMPFILE <<-EOF
        set linesize 1024
        set trimspool on
        set echo off
        set verify off
        whenever sqlerror exit failure
	startup force nomount
	alter system set db_name=$PRIMARY_INSTANCE scope=spfile;
	startup force nomount
        exit
	EOF
   ERR=$?

   if [ $ERR -ne 0 ]
   then
      log_message "Error restarting standby instance nomount.  See $TEMPFILE"
      return 1
   fi

   ERR=`check_for_sql_errors $TEMPFILE`
   if [ $ERR -ne 0 ]
   then
      log_message "Error restarting standby instance nomount.  See $TEMPFILE"
      return 2 
   fi
}

duplicate_for_standby()
{
   log_message "Duplicate for Standby"
   
   typeset target_connect_string=`get_param ${PRIMARY_INSTANCE}_USERNAME_PW`@${PRIMARY_INSTANCE}
   typeset catalog_connect_string=`get_param ${PRIMARY_INSTANCE}_CAT_CONNSTRING`

   rman 2>&1 > $TEMPFILE <<-EOF 
	connect target $target_connect_string
	connect auxiliary /
	connect catalog $catalog_connect_string
	DUPLICATE TARGET DATABASE FOR STANDBY nofilenamecheck;
	exit
	EOF
   ERR=$?

   if [ $ERR -ne 0 ]
   then
      log_message "Error running rman file $rmanfile.  See $TEMPFILE"
      return 1
   fi

   ERR=`check_for_rman_errors $TEMPFILE`
   if [ $ERR -ne 0 ]
   then
      log_message "Error running rman $rmanfile.  See $TEMPFILE"
      return 2
   fi
set +x
}

register_in_catalog()
{
   log_message "Register Standby in RMAN Catalog"
   typeset catalog_connect_string=`get_param ${STANDBY_INSTANCE}_CAT_CONNSTRING`

   rman 2>&1 > $TEMPFILE <<-EOF 
	connect target /
	connect catalog $catalog_connect_string
	@$SQLSCRIPTS/register_and_setup_catalog.rman
	exit
	EOF
   ERR=$?

   if [ $ERR -ne 0 ]
   then
      log_message "Error running rman file $rmanfile.  See $TEMPFILE"
      return 1
   fi

   ERR=`check_for_rman_errors $TEMPFILE`
   if [ $ERR -ne 0 ]
   then
      log_message "Error running rman $rmanfile.  See $TEMPFILE"
      return 2
   fi

}

init_standby()
{
   typeset standby_redo_path=`get_param STANDBY_REDO_PATH`
   log_message "Init Standby"
     sqlplus / as sysdba 2>&1 > $TEMPFILE <<-EOF
        set linesize 1024
        set trimspool on
        set echo off
        set verify off
        whenever sqlerror exit failure
   	@$SQLSCRIPTS/init_standby.sql $standby_redo_path
        exit
	EOF
   ERR=$?

   if [ $ERR -ne 0 ]
   then
      log_message "Error initializing standby instance.  See $TEMPFILE"
      return 1
   fi

   ERR=`check_for_sql_errors $TEMPFILE`
   if [ $ERR -ne 0 ]
   then
      log_message "Error initializing standby instance.  See $TEMPFILE"
      return 2 
   fi
}

convert_to_logical()
{
   log_message "Convert to Logical"
   run_sql_on_primary $SQLSCRIPTS/dbms_logstdby_build.sql
   ERR=$?
   
   if [ $ERR -ne 0 ]
   then
      log_message "Error $ERR from run_sql in convert_to_logical"
      return 1
   fi

   run_sql_on_standby "$SQLSCRIPTS/convert_to_logical.sql $STANDBY_INSTANCE"
   ERR=$?
   
   if [ $ERR -ne 0 ]
   then
      log_message "Error $ERR from run_sql in convert_to_logical"
      return 2
   fi
}

customize_standby()
{
   log_message "Customize Standby"
   run_sql_on_standby $SQLSCRIPTS/customize_standby.sql $SQLSCRIPTS/customize_standby.out
   ERR=$?
   
   if [ $ERR -ne 0 ]
   then
      log_message "Error $ERR from run_sql in customize_standby"
      return 1
   fi
}

drop_logins()
{
   log_message "Drop Logins"
   run_sql_on_standby $SQLSCRIPTS/drop_logins.sql
   ERR=$?
   
   if [ $ERR -ne 0 ]
   then
      log_message "Error $ERR from run_sql in drop_logins"
      return 1
   fi
}

drop_directories()
{
   log_message "Create Drop Directories SQL"
   run_sql_on_standby $SQLSCRIPTS/create_drop_directories.sql $TEMPDIR/drop_dirs.sql
   ERR=$?
   
   if [ $ERR -ne 0 ]
   then
      log_message "Error $ERR from run_sql creating drop_dirs.sql in drop_directories"
      return 1
   fi

   log_message "Drop Directories"
   run_sql_on_standby $TEMPDIR/drop_dirs.sql
   ERR=$?
   
   if [ $ERR -ne 0 ]
   then
      log_message "Error $ERR from run_sql in dropping dirs drop_directories"
      return 1
   fi
}

recreate_directories()
{
   log_message "Recreate Directories"
   run_sql_on_standby $TEMPDIR/saved_dirs.sql
   ERR=$?
   
   if [ $ERR -ne 0 ]
   then
      log_message "Error $ERR from run_sql in recreate_directories"
      return 1
   fi
}

recreate_logins()
{
   log_message "Recreate Logins"
   run_sql_on_standby $TEMPDIR/saved_logins.sql
   ERR=$?
   
   if [ $ERR -ne 0 ]
   then
      log_message "Error $ERR from run_sql in recreate_logins"
      return 1
   fi
}

reload_local()
{
   log_message "Reload Local"
   impdp '"/ as sysdba"' parfile=$IMP_LOCAL_DATA_PAR logfile=${LOCAL_DATA_EXP}.imp.log file=$LOCAL_DATA_EXP
}

start_apply()
{
   log_message "Start Apply"
   run_sql_on_standby $SQLSCRIPTS/start_apply.sql
   ERR=$?
   
   if [ $ERR -ne 0 ]
   then
      log_message "Error $ERR from run_sql in start_apply"
      return 1
   fi
}

check_standby_status()
{
   log_message "Check Standby Status"
   run_sql_on_standby $SQLSCRIPTS/check_standby_status.sql $LOGDIR/check_standby_status.out
   ERR=$?
   
   if [ $ERR -ne 0 ]
   then
      log_message "Error $ERR from run_sql in check_standby_status"
      return 1
   fi
   cat $LOGDIR/check_standby_status.out
}

clean_up()
{
   #rm $TEMPFILE
   echo $TEMPFILE
}

check_for_rman_errors()
{
   typeset infile=$1
   typeset return_code=0

   export ERROR_COUNT=`grep 'ERROR MESSAGE STACK' $infile |wc -l`

   if [ $ERROR_COUNT -eq 0 ]
   then
      return_code=0
   else
      log_message "$ERROR_COUNT RMAN errors found in $infile"
      return_code=2
   fi

   echo $ERROR_COUNT
   return $return_code
}

check_for_sql_errors()
{
   typeset infile=$1
   typeset return_code=0
   export ERROR_COUNT=`grep -E -c 'ORA-|SP2-|TNS-' $infile`

   if [ $ERROR_COUNT -eq 0 ]
   then
      return_code=0
   else
      log_message "$ERROR_COUNT sql errors found in $infile"
      return_code=2
   fi
   echo $ERROR_COUNT
   return $return_code
}


exit_error()
{
   log_message "$1"
   #send_notification "$1"
   clean_up
   log_message "Exiting: FAILED"
   log_message "=========================================================="
   exit $FAILURE
}

exit_success()
{
   log_message "$1"
   clean_up
   log_message "Exiting: SUCCEEDED"
   log_message "=========================================================="
   rm $RESTART_STEP_SAVE
   exit $SUCCESS
}

process_commandline()
{ 
   # Loop through command line options
   while getopts :lrt: OPTION $*
   do
      case $OPTION in
         r)  if [ -f "$RESTART_STEP_SAVE" ]
             then
                STARTING_STEP=`cat $RESTART_STEP_SAVE`
             else
                STARTING_STEP=0
             fi
             echo "-r specified. Execution beginning with saved step $STARTING_STEP"
             ;;
         t)  STARTING_STEP=$OPTARG
             echo "-t specified. Execution beginning with step $STARTING_STEP"
             ;;
         l)  LOG_TO_TERMINAL=FALSE
             ;;
         \:) print_usage
             echo "Missing argument for option: $OPTARG"
             exit $FAILURE
             ;;
         ?)  print_usage
             echo "Unknown option: $OPTION"
             exit $FAILURE
             ;;
       esac
   done


   ### Add parameter validations here....
   if [ -z "$STARTING_STEP" ]
   then
      export STARTING_STEP=0
   fi

   if [ -z "$LOG_TO_TERMINAL" ]
   then
      LOG_TO_TERMINAL=TRUE
   fi
}

print_usage()
{
   USAGE='Usage: resync_standby.ksh -p <PRIMARY_INSTANCE> -s <STANDBY_INSTANCE> -c<CATALOG_INSTANCE>'
   echo $USAGE
}

#############################################################
################## Execution Starts Here ####################
#############################################################

#------------------------------------------------------------
#  Setup environment
#------------------------------------------------------------ 
export SUCCESS=0
export FAILURE=6
export ORATAB=/etc/oratab


#------------------------------------------------------------
#  Misc. variables
#------------------------------------------------------------
# Set environment to print full date for rman output
export NLS_DATE_FORMAT='YYYY-MM-DD HH24:MI:SS'
JOB=`basename $0`
SCRIPTS=/u37/aetna/scripts
WORKHOME=$SCRIPTS/standby
CONFIGS=$WORKHOME/configs
CONFIG_FILE=$CONFIGS/resync.parm
SQLSCRIPTS=$WORKHOME/sql
TEMPDIR=$WORKHOME/tmp
RUNDATE=`date +"%Y%m%d%H%M%S"`
LOCAL_DATA_EXP=local_data.dmp
EXP_LOCAL_DATA_PAR=$CONFIGS/save_userdata.par
IMP_LOCAL_DATA_PAR=$CONFIGS/load_userdata.par
OUTPUT_PATH=$WORKHOME/logs
RESTART_STEP_SAVE=$WORKHOME/restart_step_save.out
export TEMPFILE=$OUTPUT_PATH/$$_$JOB.tmp

#------------------------------------------------------------
# Ensure Necessary Arguments Were Passed
#------------------------------------------------------------
process_commandline $*



### Begin Wallet Setup for secure external pw store
export WALLET_LOCATION=$ORACLE_BASE/oracle_wallet

#export TNS_ADMIN=$WORKHOME/tns

### End Wallet Setup

LOGDIR="$WORKHOME/logs"
LOGFILE="$LOGDIR/`date +%Y-%m-%d_%H%M%S`.log"

#### DB env setup
PRIMARY_INSTANCE=`get_param PRIMARY_INSTANCE`
STANDBY_INSTANCE=`get_param STANDBY_INSTANCE`

export PATH=$PATH:/usr/local/bin
export ORAENV_ASK=NO
export ORACLE_SID=$STANDBY_INSTANCE
. oraenv

###====================================================================

### Process Starts Here
log_message "=========================================================="
log_message "Starting: $0"
log_message "Hostname: "`hostname`
log_message "Log File: $LOGFILE"

log_message "=========================================================="

set -A job_steps check_primary \
                 check_standby \
                 save_logins \
                 save_directories \
                 export_local_data \
                 restart_standby \
		 duplicate_for_standby \
		 init_standby \
		 convert_to_logical \
		 customize_standby \
		 drop_logins \
		 drop_directories \
		 recreate_directories \
		 reload_local \
		 start_apply \
		 check_standby_status \
                 register_in_catalog

# Loop through job steps calling the 
for ((i=$STARTING_STEP;i<=${#job_steps[@]};i++))
do
   log_message "Executing Step $i: ${job_steps[i]}"
   echo $i > $RESTART_STEP_SAVE
   
   # Execute the function for this step
   ${job_steps[i]}
   ERR=$?
   if [ $ERR -ne 0 ] 
   then
      exit_error "Error $ERR from ${job_steps[i]}.  Exiting"
   fi
   log_message "Completed Step $i: ${job_steps[i]}"
done

exit_success
