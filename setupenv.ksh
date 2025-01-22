#!/bin/ksh -x

###########################################################################
# -----------------------------------------------------------
#    File: setupenv.ksh
#  Author: Mark Lantsberger 2/28/98
# Purpose: A KORN shell script to setup the environment for script execution.
#          For Oracle use.
# Info:    This script belongs in the $SCRIPTS directory.
#
#                         C H A N G E S
#
# ------------------------------------------------------------
#
# For change information see comment in PVCS
#
###########################################################################

USAGE="Usage: setupenv.ksh arg1 (arg1=ORACLE_SID)"

#------------------------------------------------------------
# Ensure Oracle Database Name Was Passed
#------------------------------------------------------------
if [ $1 ]
then
    ORACLE_SID=$1
else
    echo $USAGE
    return
fi

export ORACLE_SID       

############################################################################
function set_debugging
{
   typeset -i DebugLevel
   if [[ $DebugLevel == 9 ]]
   then
      if [ "`uname -m`" = "sun4u" ] ; then
         set -o xtrace
      else
         set -x
      fi
   else
      if [ "`uname -m`" = "sun4u" ] ; then
         set +o xtrace
      else
         set +x
      fi
   fi

   return $?
}


############################################################################
function set_scripts_variable
{
   ### Determine platform script is running on
#   if [ "`uname -m`" = "sun4u" ] ; then
#      ORATAB=`find /var -name oratab -print 2> /dev/null`
#   else
#      ORATAB=`find /etc -name oratab -print 2> /dev/null`
#   fi
ORATAB=/etc/oratab

   ### Determine scripts location from oratab file

   export FS_FOR_SCRIPTS=`awk -F: "/${ORACLE_SID}:/ {print \$4}" $ORATAB 2>/dev/null`

   export SCRIPTS=$FS_FOR_SCRIPTS/aetna/scripts

   return $?
}

############################################################################
function set_oracle_variables
{
   USAGE="Usage: set_oracle_variables arg1  (arg1=ORACLE_SID)"

   if test "$#" -lt 1
   then
     echo $USAGE
     return 1
   fi

     ### Determine platform script is running on
#     if [ "`uname -m`" = "sun4u" ] ; then
#        ORATAB=`find /var -name oratab -print 2> /dev/null`
#     else
#        ORATAB=`find /etc -name oratab -print 2> /dev/null`
#     fi
ORATAB=/etc/oratab

     export PLATFORM=`uname -m`

     export SERVER=`uname -n`

     export CONTEXT_NAME=${ORACLE_SID}_${SERVER}

     export ORACLE_HOME=`awk -F: "/^${ORACLE_SID}:/ {print \\$2}" $ORATAB`

     FS=`echo $ORACLE_HOME | awk -F/ '{print $2}'`

    #  export ORACLE_BASE="/"$FS"/app/oracle/"
#    export ORACLE_BASE=/orahome/wkab01/app/oracle

     #MFS - to fix oracle base issue.
     ORABASE_EXE=$ORACLE_HOME/bin/orabase
     unset ORACLE_BASE
     export ORACLE_BASE
     if [ -f $ORABASE_EXE ]
     then
        export ORACLE_BASE=`$ORABASE_EXE`
     else
        ORACLE_BASE=$ORACLE_HOME
     fi

#    Determine scripts location from oratab file
     export FS_FOR_SCRIPTS=`awk -F: "/^${ORACLE_SID}:/ {print \\$4}" $ORATAB`
     export FS_FOR_OUTPUTS=`awk -F: "/^${ORACLE_SID}:/ {print \\$5}" $ORATAB`

###  DISABLE AUTOMATIC TRACING OF CONNECTIONS
     export EPC_DISABLED=TRUE

     export SCRIPTS_FS=${FS_FOR_SCRIPTS}
     export INSTANCE_FS=${FS_FOR_OUTPUTS}

     export SCRIPTS=$SCRIPTS_FS/aetna/scripts   
     export INSTANCE_OUTPUTS="$INSTANCE_FS/$ORACLE_SID"

     export ORACLE_TERM=vt100
     export LD_LIBRARY_PATH=$ORACLE_HOME/lib
     export LIBPATH=$ORACLE_HOME/lib:/usr/lib
     export NLS_LANG="AMERICAN_AMERICA.WE8ISO8859P1"

     PATH=$PATH:/usr/sbin
     PATH=$ORACLE_HOME/bin:/opt/bin:/bin:/usr/bin:/usr/local/bin:/usr/openwin/bin:/usr/ccs/bin:/usr/ucb:/etc:/usr/openv/netbackup/bin:.:/usr/java14/bin:/usr/java14/jre/bin
     export PATH=$PATH:/usr/sbin

     if [ -d $ORACLE_HOME/network/admin/$CONTEXT_NAME ]
     then
          export TNS_ADMIN=$ORACLE_HOME/network/admin/$CONTEXT_NAME
     else
          export TNS_ADMIN=$ORACLE_HOME/network/admin
     fi

     if [ -d $ORACLE_HOME/admin/$CONTEXT_NAME ]
     then
          export TRACE_DEST=$ORACLE_HOME/admin/$CONTEXT_NAME
     else
          export TRACE_DEST=$ORACLE_BASE/admin/$ORACLE_SID
     fi

     export MON_DIR=$SCRIPTS/monitor
     export LSNR_LOG_FILE=$MON_DIR/lsnrctl_auto_check.log
     export MONITOR_LOG_DIR=$INSTANCE_FS/monitor
     export SPACE_LOG_DIR=$INSTANCE_FS/space

     export EMPTY_FILE=$SCRIPTS/utility/empty_file

     export MAILTO_LIST=$SCRIPTS/utility/mailto_list.dat

#    Build SQL environment file to define variables
     TEMPVAR="define ScriptsFS=${FS_FOR_SCRIPTS}"
     echo $TEMPVAR > $SCRIPTS/setup_${ORACLE_SID}.sql

     TEMPVAR="define InstanceFS=${FS_FOR_OUTPUTS}"
     echo $TEMPVAR >> $SCRIPTS/setup_${ORACLE_SID}.sql

     TEMPVAR="define DBInstance=${ORACLE_SID}"
     echo $TEMPVAR >> $SCRIPTS/setup_${ORACLE_SID}.sql

     TEMPVAR="define DateTime=${DATETIME}"
     echo $TEMPVAR >> $SCRIPTS/setup_${ORACLE_SID}.sql

   return $?
}

############################################################################
####                     GENERIC FUNCTION SECTION                       ####
############################################################################
function OnErrorExit
{
# Usage: OnErrorExit
#
# Description:  Issues an exit if return code $? is non-zero
#               Preserves error code on exit
#
# Example:
#   DoSomethingDangerous
#   OnErrorExit

typeset ErrorCode="$?"
if [[ "$ErrorCode" -ne 0 ]]
   then
   DebugMsg 1 Exiting with code of $ErrorCode
   exit $ErrorCode
fi
} 

############################################################################
function DebugMsg
{
# Usage: DebugMsg <DebugLevel> <Arguments to display as message>
#
# DebugLevel 1=error 5=info 10=debug
# Do not print anything for DebugLevel=0
#
# Example:
#   DebugMsg 5 Your wish is my command

# Local variables
typeset Prefix=""
typeset Parameter1=""

# User variables
# DebugLevel 1=Error 5=info 10=debug
if [[ "$DebugLevel" == "" ]]
   then
   DebugLevel=1
fi

# Parameter checking
if [[ "$1" == "" ]]
   then
   return
fi

# Begin Execution
if (( $DebugLevel <= 0 ))
   then
   return
fi

# For 5 and above put the program name
if (( $DebugLevel >= 5 ))
   then
   Prefix=`basename $0`
fi

# For 10 and above put the process id
if (( $DebugLevel >= 10 ))
   then
   Prefix=${Prefix}'['"$$"".${1}"']'
fi
# Starting at 5 (where there IS a prefix) add a tab between
if (( $DebugLevel >= 5 ))
   then
   Prefix="${Prefix}:\t"
fi

if (( $1 <= $DebugLevel ))
   then
   shift
   # The - is to prevent interpretation of - as part of $Prefix
   print - ${Prefix} $*
fi
}

############################################################################
function set_date
{
#set -o xtrace

   #------------------------------------------------------------
   # Extract the current year, month day and hour for this run of
   # scan_log (i.e., previous hour of this day).
   #------------------------------------------------------------
   export MON=`date +"%h"`
   export YEAR=`date +"%Y"`
   export DAY=`date +"%a"`
   export DAYNUM=`date +"%d"`
   export HOUR=`date +"%T" | cut -c1-2`
   export MIN=`date +"%T" | cut -c4-5`
   export DATE_VARIABLE="`date +%Y%m%d_%T`"
   export DATETIME="`date +%Y%m%d_%T`"

   return $?
}

############################################################################
function display_environment
{
#set -o xtrace

   ### Display some environment settings

   echo 'ORACLE_SID 	' $ORACLE_SID
   echo 'ORACLE_HOME 	' $ORACLE_HOME
   echo 'ORACLE_BASE	' $ORACLE_BASE
   echo 'LD_LIBRARY_PATH ' $LD_LIBRARY_PATH
   echo 'LIBPATH ' $LIBPATH
   echo 'PATH  '	 $PATH

   return $?
}

############################################################################
function routeto
{
#set -o xtrace

   typeset -i num=0
   typeset -i answer
   typeset -l routeto

   cat $MAILTO_LIST | awk -F" " '{if ($4 == "menu") print $3}' | sort -u | while read LINE
   do
       case $LINE in
           \#*) ;;
           *)

           num=`expr $num + 1`           
           echo $num". " $LINE

           ;;
       esac
   done


   echo "   Enter routing destination: \c"

   read answer 

   typeset -i num=0
   cat $MAILTO_LIST | awk -F" " '{if ($4 == "menu") print $3}' | sort -u | while read LINE
   do
       case $LINE in
           \#*) ;;
           *)

           num=`expr $num + 1`

           if [ $num = $answer ] ; then
               echo $LINE > $SCRIPTS/dynamic/routeto
           fi

           ;;
       esac
   done

   return $?
}

############################################################################
function processes_cpu
{
#
#  List Current running processes by CPU usage
#
   ps -e -o pcpu,time,stime,user,pid,fname,vsz | egrep -v root | egrep -v ora_ | egrep -v tnslsnr | egrep -v "PID COMMAND" | sort -r -k 1 | more

   return $?
}

############################################################################
function processes_time
{
#
#  List Current running processes by time usage
#
   ps -e -o pcpu,time,stime,user,pid,fname,vsz | egrep -v root | egrep -v ora_ | egrep -v tnslsnr | egrep -v "PID COMMAND" | egrep -v _ | sort -r -k 2 | more

   return $?
 }

############################################################################
function MailIt
{
   #
   # Usage: MailIt <message> <file> <mailing list>
   #
   #

   USAGE="Usage: MailIt arg1 arg2 arg3 arg4 (arg1=message,arg2=file to mail,arg3=mailing list,arg4=type mailing)"

   if test "$#" -lt 4
   then
     echo $USAGE
     return 1
   fi

   message=$1
   file=$2
   list=$3
   type=$4
            
   cat $MAILTO_LIST | while read LINE
   do
        case $type in
 		email)
                    MAILID=`echo $LINE | awk '{print $1}'`
                    ;;
               pager)
                     MAILID=`echo $LINE | awk '{print $2}'`
                    ;;
              *)
                    echo "Unknown type entered"
                    return 1
                    ;;
        esac


      LIST=`echo $LINE | awk '{print $3}'`
      if [[ "$list" == "$LIST" ]]
      then
         mailx -s "$message" $MAILID < $file
      fi
   done

   return $?
}

############################################################################
function GetProcessStatus
{
   USAGE="Usage: GetProcessStatus arg1 (arg1=process name)"

   if test "$#" -lt 1
   then
     DebugMsg 1 $USAGE
   fi

  str=$1

  STATUS=`ps -ef | cut -c48- | grep $str | grep -v grep | awk '{ printf $NF"\n" }'`
  case $STATUS in
    $str) return 0;;
       *) return 1;;
  esac

return $?
}

############################################################################
function help_functions
{
   USAGE="Usage: help_functions arg1 (arg1=ksh name)"

#   if test "$#" -lt 1
#   then
#     DebugMsg 1 $USAGE
#   fi

#  kshname=$1

  echo " "
  echo "setupenv.ksh functions"
  cat $SCRIPTS/setupenv.ksh | grep function | awk '{if ($1 == "function") print $2 }'
  echo " "
  echo "runsql_lib.ksh functions"
  cat $SCRIPTS/runsql_lib.ksh | grep function | awk '{if ($1 == "function") print $2 }'

return $?
}


### PROCESS SECTION
###====================================================================
### Process Starts Here 

set_date

set_oracle_variables $ORACLE_SID

display_environment

echo "Environment variables loaded."

export PS1="`hostname`:$ORACLE_SID:"
