#!/bin/ksh
# set -x

export PATH=/usr/bin:/etc:/usr/ccs/bin:/usr/sbin:/usr/ucb:/usr/lbin:/usr/local/bin:/usr/bin/X11:/sbin:.:/home/oracle/Bin

export ORACLE_SID=$1

if [ -z "$ORACLE_SID" ]
then
   echo "!!! Oracle SID not set"
   echo "!!! Please supply a SID as the 1st argument to this script."
fi

export LOGFILE=/tmp/${ORACLE_SID}_truncate_session.log

# use ORACLE provided script - oraenv - to set up ORACLE_HOME and PATH
# ASK variable prevents prompting since we set up the default above...
ORAENV_ASK=NO
. /usr/local/bin/oraenv

export TNS_ADMIN=$ORACLE_HOME/network/admin

sqlplus -S -L /nolog <<-EOF > $LOGFILE
	set echo on
	connect / as sysdba
	truncate table wkab10.t_session_data;
	truncate table wkab10.t_session_detail;
	truncate table wkab10.t_emp_search_results;
	exit

date 

