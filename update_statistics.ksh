#!/bin/ksh
# -----------------------------------------------------------
#    File: update_statistics.ksh
#  Author: Mark Lantsberger 09/18/2000
# Purpose: A KORN shell script to update statistics.
#
#
# -----------------------------------------------------------

USAGE="Usage: update_statistics.ksh arg1 (arg1=ORACLE_SID)"

if [ $1 ]
then
    ORACLE_SID=$1
else
    echo $USAGE
    exit
fi

. $HOME/setup_env.ksh $ORACLE_SID


#    ------------------------------------------------------------
#    Output file names
#
#    ------------------------------------------------------------
RUNTHISQL=$SCRIPTS/maint/SQL/update_statistics.sql
OUTPUT1=$SCRIPTS/maint/output1.out
OUTPUT2=$SCRIPTS/maint/output2.out

#
#  Functions for processing
#

###------------------------------------------------
clean_up()
{
   rm -f $OUTPUT1
   rm -f $OUTPUT2

   return $?
}

#
#  Run PL/SQL
#
###------------------------------------------------
run_sql()
{
   #   Run statistics on ALL tables and indexes for application

   COUNTEM=`ps -ef | grep $RUNTHISQL | egrep -v grep | egrep -v ksh | egrep -v sh | wc -l`

   if [ $COUNTEM == 0 ]
   then
      sqlplus generic/sql @$RUNTHISQL $ORACLE_SID
      MailIt "${ORACLE_SID} Run Statistics Complete" $OUTPUT1 dba email
   fi

   return $?
}


#
# Mail Reports 
#

###------------------------------------------------
mail_outputs()
{

   if [ -s $OUTPUT1 ]
   then
#      MailIt "${ORACLE_SID} CC Manager Errors" $OUTPUT1 dba email
       echo "Made it here"
   fi


   return $?
}

###====================================================================
### Process Starts Here

clean_up

run_sql

#mail_outputs


