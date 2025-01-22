#!/bin/ksh
# -----------------------------------------------------------
#    File: spcmgmt.ksh
#  Author: Mark Lantsberger
# Purpose: A KORN shell script to clean-up space logs.
#
#                         C H A N G E S
#
# ----------------------------------------------------------
#  DATE        VERSION  COMMENT               WHO 
#  For change information see comment in PVCS
# 
# -----------------------------------------------------------  
USAGE="Usage: spcmgmt.ksh arg1 (arg1=ORACLE_SID)"

if [ "$1" ]
then
   ORACLE_SID=$1
#   echo "ORACLE_SID " $ORACLE_SID
else
   echo $USAGE
   exit
fi  

if [ "$2" ]
then
   MODIFIED=$2
#   echo " MODIFIED " $MODIFIED
else
   # MODIFIED default is 15 days
   MODIFIED=+15
fi

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

#
# compress space monitor reports other than the current
#
  mv $INSTANCE_OUTPUTS/space/spacemon.lst $INSTANCE_OUTPUTS/space/spacemon.lst_$DATE_VARIABLE


gzip   $INSTANCE_OUTPUTS/space/spacemon.lst*

echo 'Monitor reports older than  1 day compressed for '$DATE_VARIABLE


