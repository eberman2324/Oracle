#!/bin/sh
#
# Copyright (c) 1996 Qualix Group, Inc. All Rights Reserved.
#

if test "$#" -ne 1
then
  echo "Usage: $0 oratab"
  exit 1
fi

oratab=$1

check_sga()
{
  sid=$1
  dbf=${ORACLE_HOME}/dbs/sgadef${sid}.dbf

  if test -f ${dbf}
  then
    return 0
  else
    return 1
  fi
}

check_connection()
{
  ${ISQL} > /tmp/$$.out 2> /tmp/$$.err <<EOF
connect internal;
select sysdate from dual;
exit;
EOF

  grep SYSDATE /tmp/$$.out >/dev/null 2>&1
  if test "$?" -ne 0
  then
    cat /tmp/$$.*
    rv=1
  else
    rv=0
  fi

  /bin/rm -f /tmp/$$.*

  return $rv
}

get_status()
{
  str=$1
  STATUS=`ps -ef | cut -c48- | grep -w $str | grep -v grep`
  case $STATUS in
    $str) return 0;;
       *) return 1;;
  esac
}
#
#checks for smon process
#
check_smon()
{
  sid=$1
  get_status ora_smon_$sid
  return $?
}

#
#checks for pmon process
#
check_pmon()
{
  sid=$1
  get_status ora_pmon_$sid
  return $?
}

#
#checks for dbwr process
#
check_dbwr()
{
  sid=$1
  get_status ora_dbwr_$sid
  return $?
}

#
#checks for lgwr process
#
check_lgwr()
{
  sid=$1
  get_status ora_lgwr_$sid
  return $?
}

#
#checks for reco process
#
check_reco()
{
  sid=$1
  get_status ora_reco_$sid
  return $?
}

#
# Beeper message
#
beeper_message()
{
   sid=$1

   # Paging thru PAGENET.NET
   $MAILTO "SIFD - Dev. $sid database instance is down" $EMPTY_FILE $MAILPAGER_FILE

   return $?
}

#
# Mail Messaging
#
mail_message()
{
   sid=$1
   
   $MAILTO "SIFD - Dev. $sid database instance is down" $EMPTY_FILE

   return $?
}

######################################################################
SCRIPTS='/u302/scripts'
#  Set corporate environment variables
. $SCRIPTS/corpenv

cat $oratab | while read LINE
do
  case $LINE in
    \#*)		;;	#comment-line in oratab
    *)
# Proceed only if third field is 'Y'.
      if [ "`echo $LINE | awk -F: '{print $3}' -`" = "Y" ] ; then
        ORACLE_SID=`echo $LINE | awk -F: '{print $1}' -`
        if [ "$ORACLE_SID" = '*' ] ; then
          ORACLE_SID=""
        fi
        # Called programs use same database ID
        export ORACLE_SID
        ORACLE_HOME=`echo $LINE | awk -F: '{print $2}' -`
        # Called scripts use same home directory
        export ORACLE_HOME
        # Put $ORACLE_HOME/bin into PATH and export.
        PATH=$ORACLE_HOME/bin:${PATH}; export PATH

        if test -f $ORACLE_HOME/bin/svrmgrl
        then
          ISQL=svrmgrl
        fi

	check_sga ${ORACLE_SID}
	if test "$?" -ne 0
	then
	  echo "ORACLE: System Global Area for ORACLE_SID=${ORACLE_SID} is not OK."
          beeper_message ${ORACLE_SID}
          mail_message ${ORACLE_SID}
	  exit 1
        fi

	check_connection ${ORACLE_SID}
	if test "$?" -ne 0
	then
	  echo "ORACLE: Cannot connect to database for ORACLE_SID=${ORACLE_SID}."
          beeper_message ${ORACLE_SID}
          mail_message ${ORACLE_SID}
          exit 1
        fi

	check_smon ${ORACLE_SID}
	if test "$?" -ne 0
	then
	  echo "ORACLE: System monitor for ORACLE_SID=${ORACLE_SID} is NOT running."
          beeper_message ${ORACLE_SID}
          mail_message ${ORACLE_SID}
	  exit 1
        fi

	check_pmon ${ORACLE_SID}
	if test "$?" -ne 0
	then
	  echo "ORACLE: Process monitor for ORACLE_SID=${ORACLE_SID} is NOT running."
          beeper_message ${ORACLE_SID}
          mail_message ${ORACLE_SID}
	  exit 1
        fi

        check_dbwr ${ORACLE_SID}
	if test "$?" -ne 0
	then
	  echo "ORACLE: Database writer for ORACLE_SID=${ORACLE_SID} is NOT running."
          beeper_message ${ORACLE_SID}
          mail_message ${ORACLE_SID}
	  exit 1
        fi

        check_lgwr ${ORACLE_SID}
	if test "$?" -ne 0
	then
	  echo "ORACLE: Log writer for ORACLE_SID=${ORACLE_SID} is NOT running."
          beeper_message ${ORACLE_SID}
          mail_message ${ORACLE_SID}
	  exit 1
        fi

	if test ! -z "${CHECK_RECO}"
	then
          check_reco ${ORACLE_SID}
	  if test "$?" -ne 0
	  then
	    echo "ORACLE: Distributed transaction recovery process for ORACLE_SID=${ORACLE_SID} is NOT running."
	    exit 1
          fi
	fi
      fi # yes on oratab
      ;;
  esac	# non-empty line
done
