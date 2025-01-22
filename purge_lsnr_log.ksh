#!/bin/ksh                                 


# -----------------------------------------------------------
#    File: purge_lsnr_log.ksh
#  Author: John Semencar 07/02/2003
# Purpose: compresses existing log monthly
#
#
#                         C H A N G E S
#
# ----------------------------------------------------------
#  DATE        VERSION  COMMENT                                     WHO 
#  For change information see comment in PVCS
#                       
#
###########################################################################
# -----------------------------------------------------------
USAGE="Usage: purge_lsnr_log.ksh arg1 (arg1=ORACLE_SID)"


typeset -u ORACLE_SID=$1	# UPPER CASE
typeset -l lORACLE_SID=$1	# lower case

#------------------------------------------------------------
# Ensure Necessary Arguments Were Passed
#------------------------------------------------------------
   if test "$#" -lt 1
   then
     echo $USAGE
     return 1
   fi

   export ORACLE_SID=$1
   export lORACLE_SID=$1

                                           
#------------------------------------------------------------
#  Setup environment
#------------------------------------------------------------
### Determine platform script is running on
if [ "`uname -m`" = "sun4u" ] ; then
   ORATAB=`find /var -name oratab -print 2> /dev/null`
else
   ORATAB=`find /etc -name oratab -print 2> /dev/null`
fi

### Determine scripts locaation from oratab file
cat $ORATAB | while read LINE
do
    case $LINE in
        \#*)            ;;      #comment-line in oratab
        *)
        ORATAB_SID=`echo $LINE | awk -F: '{print $1}' -`
        if [ "$ORATAB_SID" = '*' ] ; then
               ORATAB_SID=""
        fi

        if [ "$ORACLE_SID" = "$ORATAB_SID" ] ; then
#          Get Script Path from oratab file.
           FS_FOR_SCRIPTS=`echo $LINE | awk -F: '{print $4}' -`
        fi
    ;;
    esac
done

export SCRIPTS=$FS_FOR_SCRIPTS/aetna/scripts

. $SCRIPTS/setupenv.ksh $ORACLE_SID

#------------------------------------------------------------
#  Clearing listener log
#------------------------------------------------------------

echo "Clearing listener log file"
                                           
cd $TNS_ADMIN

echo "set current_listener $ORACLE_SID" > listener_run1.txt
echo "set log_file listener_tmp"  >> listener_run1.txt
echo "exit"  >> listener_run1.txt

lsnrctl @listener_run1.txt


sleep 5                                    
mv $lORACLE_SID.log $lORACLE_SID.log.$DATETIME            

echo "set current_listener $ORACLE_SID" > listener_run2.txt
echo "set log_file $ORACLE_SID"  >> listener_run2.txt
echo "exit"  >> listener_run2.txt

lsnrctl @listener_run2.txt


cat listener_tmp.log >> $lORACLE_SID.log.$DATETIME
gzip $lORACLE_SID.log.$_date                 
                                           
exit                                       