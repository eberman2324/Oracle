#!/bin/ksh

###############################################################################
#
# "relink_onsites.ksh" will relink ORACLE_HOME(s), then call the
# start_databases.ksh script to startup the listener(s) and its database(s).
# this script to be used by the onsites for dev and qa only.
# this script is run as a job in OEM.
# the OEM job name is: RELINK_ONSITES_aorinfw1d
# ... jrs
#
###############################################################################

#. ~/.profile

####
#######
#########

_date=$(date +'%Y%m%d_%H%M')
_server_name=`uname -n`
ORATAB=/etc/oratab
DBADIR=${HOME}/relink
LOGDIR=${DBADIR}/logs
UTLDIR=${DBADIR}/utl
STARTDB=${HOME}/local/start_oracle_processes.ksh

_OhomeList=${UTLDIR}/OhomeList_${_date}.lst
_out_rootsh=${UTLDIR}/rootsh_${_date}.out
_out=${LOGDIR}/relink_${_date}.out
_out_mailSend=${LOGDIR}/mailSend_${_date}.out

typeset -u inp
cat /dev/null > ${_OhomeList}
cat /dev/null > ${_out}
cat /dev/null > ${_out_rootsh}
cat /dev/null > ${_out_mailSend}

teeout () {
  tee -a  ${_out}
}

#------------------------------------------------------------------------------
#
##
### begin...

print                                                              | teeout
print "begin:  $0"                                                 | teeout
print "date:   `date`                   server: ${_server_name}"   | teeout
print

###
### check if this script already running..
###

integer SCRPTCNT=0
print -n "if this script already running.. "       | teeout
SCRPTCNT=`ps -ef | grep -i "onsites_relink_aorinfw1d.ksh" |grep -v grep |wc -l`
print "SCRPTCNT:" ${SCRPTCNT}  | teeout
if [ ${SCRPTCNT} -gt 2 ]; then
 echo 'RELINK_ONSITES_aorinfw1d Overlap' | sendmail -r bermane@aetna.com -v 8603928025@vtext.com
 echo 'RELINK_ONSITES_aorinfw1d Overlap' | sendmail -r bermane@aetna.com -v bermane@aetna.com
 #echo 'RELINK_ONSITES_aorinfw1d Overlap' | sendmail -r SchloendornT@aetna.com -v 2152625546@vtext.com
 #echo 'RELINK_ONSITES_aorinfw1d Overlap' | sendmail -r SchloendornT@aetna.com -v SchloendornT@aetna.com
 exit 1
fi

#print "Sleeping for 2 min..."  | teeout  
#sleep 120
print "PASS"     | teeout

###
### check all dbs and listeners must be down...
###

print -n "checking db(s) and listener(s) are down ... "       | teeout

/usr/bin/ps -ef |grep ora_smon | grep -v grep >> ${_out}
if [ $? -eq 0 ]; then
  echo "FAIL"                                                 | teeout
  echo                                                        | teeout
  echo "|*|ERROR: One or more dbs are still running..."       | teeout
  echo "|*|exiting this script..."                            | teeout
  echo                                                        | teeout
  
  echo 'One or more dbs are still running on aorinfw1d...' | sendmail -r bermane@aetna.com -v 8603928025@vtext.com
  echo 'One or more dbs are still running on aorinfw1d...' | sendmail -r bermane@aetna.com -v bermane@aetna.com
  #echo 'One or more dbs are still running on aorinfw1d...' | sendmail -r SchloendornT@aetna.com -v 2152625546@vtext.com
  #echo 'One or more dbs are still running on aorinfw1d...' | sendmail -r SchloendornT@aetna.com -v SchloendornT@aetna.com 
  exit 1

fi

/usr/bin/ps -ef | grep tnslsnr | grep -v grep >> ${_out}
if [ $? -eq 0 ]; then
  echo "FAIL"                                                 | teeout
  echo                                                        | teeout
  echo "|*|ERROR: One or more listeners are still running..." | teeout
  echo "|*|exiting this script..."                            | teeout
  echo                                                        | teeout
  echo 'One or more listeners are still running on aorinfw1d...' | sendmail -r bermane@aetna.com -v 8603928025@vtext.com
  echo 'One or more listeners are still running on aorinfw1d' | sendmail -r bermane@aetna.com -v bermane@aetna.com
  #echo 'One or more listeners are still running on aorinfw1d...' | sendmail -r SchloendornT@aetna.com -v 2152625546@vtext.com
  #echo 'One or more listeners are still running on aorinfw1d' | sendmail -r SchloendornT@aetna.com -v SchloendornT@aetna.com 
  exit 1
fi

print "PASS"     | teeout

###
### building list of ORACLE_HOMEs to relink...
###

print -n "building list of ORACLE_HOMEs to relink ... "       | teeout

cat ${ORATAB} | while read SIDLINE
do
  case ${SIDLINE} in
     "")  ;;  ### it's a blank line...
    \#*)  ;;  ### it's a comment line...
    \**)  ;;  ### it's an asterisk line...
      *)  sid=`echo ${SIDLINE}     | cut -f 1 -d :`
          sidhome=`echo ${SIDLINE} | cut -f 2 -d :`
          sidyes=`echo ${SIDLINE}  | cut -f 3 -d :`
          echo ${sid} | grep -i agent >/dev/null     ### do not relink the agent
          if [ $? -eq 1 ]; then
            if [ ${sidyes} = "Y" ]; then
              ### add the ORACLE_HOME if it hasn't been added to $_OhomeList
              grep ${sidhome} ${_OhomeList} >/dev/null
              if [ $? -eq 1 ]; then
                echo "${sid}:${sidhome}" >> $_OhomeList
              fi
            fi
          fi
          ;;
  esac
done

### ensure the ORACLE_HOMEs exist...

if [ ! -s ${_OhomeList} ]; then
  echo "FAIL"                                              | teeout
  echo                                                     | teeout
  echo "|*|ERROR: ${_OhomeList}  is empty..."              | teeout
  echo "|*|exit'ing script $0..."                          | teeout
  echo                                                     | teeout
  exit 1
fi

cat ${_OhomeList} | while read OHOMELINE
do
  Ohome=`echo ${OHOMELINE} | cut -f 2 -d :`
  if [ ! -d ${Ohome} ]; then
  echo "FAIL"                                              | teeout
  echo                                                     | teeout
  echo "|*|ERROR: ${Ohome}  is not found..."               | teeout
  echo "|*|exit'ing script $0..."                          | teeout
  echo                                                     | teeout
  exit 1
  fi
done

print "PASS"     | teeout

#
##
###
##### relink all ...
###
##
#

##################################Relink all ORACLE_HOMEs in the list...

### Add actual relink code below ##
print  | teeout

sudo genkld | wc -l
sudo slibclean
sudo genkld | wc -l


cat ${_OhomeList} | while read SIDLINE
do
  sid=`echo ${SIDLINE}   | cut -f 1 -d :`
  . ${SETUPENV} ${sid}   >> ${_out}
  #. /u01/app/oracle/aetna/scripts/oraprof ${sid} >> ${_out}
  print -n "relinking ${ORACLE_HOME} ..."       | teeout
  relink all             >> ${_out}
  print "PASS"                                  | teeout
done


print "log(s):"   | teeout
cat ${_OhomeList} | while read OHOMELINE
do
  Ohome=`echo ${OHOMELINE} | cut -f 2 -d :`
  print " ${Ohome}/install/relink.log"          | teeout
  #grep -i error ${Ohome}/install/relink.log | grep -v "^ld" >/dev/null
  ERRCNT=0
  ERRCNT=`egrep -i "fatal|error|cannot|warning|severe" ${Ohome}/install/relink.log |egrep -v "Duplicate symbol|TOC overflow|0711-773|0711-415|0711-319|0711-301|0711-224|0711-345|1254-004|1254-005|0711-786|libpfo.a|pcscfg|Cannot find a rule to create target install from dependencies.|vpxoci_StmtGetErrorCode"|wc -l`
  if [ ${ERRCNT} -gt 0 ] ; then
       echo
       echo " |*| there may be errors in the above relink log..."      >> ${_out}
       echo " |*| to see if valid error, grep the relink log above..." >> ${_out}
       echo
       echo 'Errors Encountered relinking on aorinfw1d' | sendmail -r bermane@aetna.com -v 8603928025@vtext.com
       echo 'Errors Encountered relinking on aorinfw1d' | sendmail -r bermane@aetna.com -v bermane@aetna.com
       #echo 'Errors Encountered relinking on aorinfw1d' | sendmail -r SchloendornT@aetna.com -v 2152625546@vtext.com
       #echo 'Errors Encountered relinking on aorinfw1d' | sendmail -r SchloendornT@aetna.com -v SchloendornT@aetna.com
       exit 1
    else
       echo
       echo " |*| No Errors Encountered relinking on DPPDEV" >> ${_out}
       echo 'Relink completed on aorinfw1d. No Errors Encountered' | sendmail -r bermane@aetna.com -v 8603928025@vtext.com
       echo 'Relink completed on aorinfw1d. No Errors Encountered' | sendmail -r bermane@aetna.com -v bermane@aetna.com
       #echo 'Relink completed on aorinfw1d. No Errors Encountered' | sendmail -r SchloendornT@aetna.com -v 2152625546@vtext.com
       #echo 'Relink completed on aorinfw1d. No Errors Encountered' | sendmail -r SchloendornT@aetna.com -v SchloendornT@aetna.com
       echo
    fi
    #if [ $? -eq 0 ]; then
    #echo " |*| there may be errors in the above relink log..."      >> ${_out}
    #echo " |*| to see if valid error, grep the relink log above..." >> ${_out}
  #fi
done

#############################
print "On ${_server_name}, as root, pls run the following script(s) and take the
 defaults if prompted :\n" > ${_out_rootsh}

print "root.sh:"  | teeout
cat ${_OhomeList} | while read OHOMELINE
do
  Ohome=`echo ${OHOMELINE}   | cut -f 2 -d :`
  print " ${Ohome}/root.sh"  | tee -a ${_out} ${_out_rootsh}
done

### Send email to onsites

print -n "sending emails to onsites ...... "                  | teeout

# Set Email Distribution List
MAILIDSONSITES=`paste -s /orahome/allu01/aetna/scripts/utility/onsites_mail_list`

cat "${_out_rootsh}" | mailx -s "${_server_name} - Pls run root.sh ..." bermane@aetna.com
#cat "${_out_rootsh}" | mailx -s "${_server_name} - Pls run root.sh ..." SchloendornT@aetna.com
#mailx -s "${_server_name} - Oracle relink done" ${MAILIDSONSITES} < ${_out_mailSend}
#cat "${_out_rootsh}" | mailx -s "${_server_name} - Pls run root.sh ..." ${MAILIDSONSITES}

###
### check the last email sent...
###

if [ $? -ne 0 ]; then
  echo "FAIL"                                                 | teeout
  echo                                                        | teeout
  echo "|*|ERROR: problem sending email to onsites ..."       | teeout
  echo "|*|copy/paste the root.sh lines displayed above"      | teeout
  echo "|*|and email them to the AIX point of contact..."     | teeout
  echo                                                        | teeout
else
  echo "PASS"                                                 | teeout
fi

##################
### done...
##
#

print                     | teeout
print "done: $0"          | teeout
print "date: `date`"      | teeout
print                     | teeout
exit 0

