#!/bin/ksh

# Set Current Date
DATEV="`date +%Y-%m-%d`"

# Set Relink Log Name (18c onward)
FN=relinkActions${DATEV}

# Initialize Work Variables
integer CNT=0
integer ERRCNT=0

# Loop Through oratab
cat /etc/oratab|egrep -iv "^#|gcagent|+asm|grid" | awk -F: '{print $2}'|sort -u|while read OH

do

# If Dummy Entry
if [ ! -d ${OH}/install ] ; then
   continue
fi

# Initialize Loop Variable
let CNT=0

# If Pre 18c DataBase
if [ -f ${OH}/install/relink.log ] ; then
   ls -l ${OH}/install/relink.log
   CNT=`egrep -i "fatal|error|cannot|warning|severe" ${OH}/install/relink.log |egrep -v "Duplicate symbol|TOC overflow|0711-773|0711-415|0711-319|0711-301|0711-224|0711-345|libpfo.a|pcscfg|Cannot find a rule to create target install from dependencies.|vpxoci_StmtGetErrorCode|make\: \[ijssu\] Error 1 \(ignored\)|make:\ \[iextjob\] Error 1 \(ignored\)|\[iextjob\] Error 1 \(ignored\)"|wc -l`
 if [ ${CNT} -gt 0 ] ; then
    ((ERRCNT = $ERRCNT + ${CNT}))
    continue
 else
    continue
 fi
fi

# Check For Log
CNT=`ls -1tr ${OH}/install/${FN}*.log 2> /dev/null |wc -l`

if [ ${CNT} -gt 0 ] ; then
   FN=`ls -1tr ${OH}/install/${FN}*.log |tail -1`
   ls -l ${FN}
   CNT=`egrep -i "fatal|error|cannot|warning|severe" ${FN} |egrep -v "Duplicate symbol|TOC overflow|0711-773|0711-415|0711-319|0711-301|0711-224|0711-345|libpfo.a|pcscfg|Cannot find a rule to create target install from dependencies.|vpxoci_StmtGetErrorCode|make\: \[ijssu\] Error 1 \(ignored\)|make:\ \[iextjob\] Error 1 \(ignored\)|\[iextjob\] Error 1 \(ignored\)"|wc -l`
 if [ ${CNT} -gt 0 ] ; then
    ((ERRCNT = $ERRCNT + ${CNT}))
 fi
fi

done

exit ${ERRCNT}

