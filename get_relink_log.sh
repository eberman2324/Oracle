#!/bin/ksh

# Set Current Date
DATEV="`date +%Y-%m-%d`"

# Set Relink Log Name (18c onward)
FN=relinkActions${DATEV}

# Loop Through oratab
cat /etc/oratab|egrep -iv "^#|gcagent|+asm|grid" | awk -F: '{print $2}'|sort -u|while read OH

do

# If Dummy Entry
if [ ! -d ${OH}/install ] ; then
   continue
fi

# If Pre 18c DataBase
if [ -f ${OH}/install/relink.log ] ; then
   ls -l ${OH}/install/relink.log
   continue
fi

# Check For Log
CNT=`ls -1tr ${OH}/install/${FN}*.log 2> /dev/null |wc -l`

if [ ${CNT} -gt 0 ] ; then
   FN=`ls -1tr ${OH}/install/${FN}*.log |tail -1`
   ls -l ${FN}
else
   echo "Relink Log For ${OH} Not Found"
fi

done

