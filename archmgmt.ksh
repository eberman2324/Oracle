#!/bin/ksh
# -----------------------------------------------------------
#    File: archmgmt.ksh
#  Author: Mark Lantsberger
# Purpose: A KORN shell script to clean-up archive logs.
#
#
#                         C H A N G E S
#
# ----------------------------------------------------------
#  DATE        VERSION  COMMENT               WHO 
#  For change information see comment in PVCS
#
# -----------------------------------------------------------
USAGE="Usage: archmgmt.ksh arg1 (arg1=ORACLE_SID)"
 
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
   # MODIFIED default is 2 days
   MODIFIED=+2 
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
# remove archive logs older than 2 days

#


find $INSTANCE_OUTPUTS/arch/ -depth -type f -mtime $MODIFIED -exec ls -l {} \;

find $INSTANCE_OUTPUTS/arch/ -depth -type f -mtime $MODIFIED -exec rm -f {} \;

echo 'archive logs older than  2 days removed for '$DATE_VARIABLE

#
# compress remaining archive logs

#
 gzip   $INSTANCE_OUTPUTS/arch/*.arc
