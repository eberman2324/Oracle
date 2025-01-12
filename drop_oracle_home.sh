#!/bin/bash
################################################################################################################3333333333333
#  drop_oracle_home.sh is executed to drop unsed oracle homes 
#
#  usage: $  drop_oracle_home.sh  <dbms_psu_version>   
#
#
#  Maintenance Log:
#  version 1.0 07/19/2017      R. Ryan     New Script 
#  version 1.1 08/21/2017      R. Ryan     Corrected log file name 
#  version 2.0 12/17/2018      R. Ryan     Extended functionality to GI homes 
#  version 3.0 01/19/2021      R. Ryan     Modified script to accomodate new joint CVS/Aetna standard
#
#############################################################################################################################
# Function : Log message to syslog and console
log_console () {
  echo  "$*" | tee -a $LOGFILE
}

remove_home () {
log_console "Destructive Action! Are you sure you want to drop $ORACLE_HOME?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) $ORACLE_HOME/oui/bin/detachHome.sh | tee -a $LOGFILE
              cd  $ORACLE_BASE/product
              rm -rf $VERSION
              if [ $? -eq 0 ] ; then
                log_console " "
                log_console "Oracle Home $ORACLE_HOME has been removed".
              else
                log_console " "
                log_console "Removal of oracle home $ORACLE_HOME has failed!"
                exit 1
              fi
              break;;
        No ) log_console "User Replies NO, exiting with no action taken" 
             exit 1;;
    esac
done
}

update_oratab () {

cp /etc/oratab /tmp/oratab_$DATEVAR
#sed -i "/${PSU}/d" /etc/oratab
grep -v $VERSION/ /etc/oratab > /tmp/oratab.new
cp /tmp/oratab.new /etc/oratab
rm /tmp/oratab.new

}

# End of functions


source ~oracle/std.env
DATEVAR=$(date +'%Y%m%d_%s')
LOGDIR=${STD_DBMS_DIR}/app/oracle/local/logs
LOGFILE=$LOGDIR/drop_oracle_home_$2_$DATEVAR.out
. ~/.bash_profile >/dev/null
head -1 $SCRIPTS/README.txt >> $LOGFILE
echo ' ' >> $LOGFILE

if [ $# -ne 1 ]; then
  log_console "Usage: $0  dbms_version "
  log_console Parms: $*
  exit 1
fi

log_console "Start drop oracle home $1 on  `uname -svrn` at `date` using $0"
log_console " " 
log_console "Review log file $LOGFILE for details"
log_console " "


export VERSION=$1
export MAJOR_REL=`echo $VERSION | tr -d . | cut -c1-2`
export SERVER_NAME=`echo $HOSTNAME | cut -d . -f1`


if [ -d $ORACLE_BASE/product/${VERSION}/db_1 ]; then
  log_console "Oracle DBMS software version $VERSION is installed, continuing with oracle home drop..... "
  export ORACLE_HOME=$ORACLE_BASE/product/${VERSION}/db_1
  if [ "$MAJOR_REL" -gt "12" ]; then
    PSU=`echo $VERSION | tr -d .`
  else
    PSU=`echo $VERSION | cut -d . -f5`
  fi
else
  if [ -d $ORACLE_BASE/product/${VERSION}/grid ]; then
    log_console "Oracle Grid Infrastructure software version $VERSION is installed, continuing with oracle home drop..... "
    export ORACLE_HOME= $ORACLE_BASE/product/${VERSION}/grid
    PSU=`echo $VERSION | tr -d . `
  else
    log_console "Oracle software version $VERSION is not installed. Ensure $VERSION is correct"
    exit 1
  fi
fi

# Check to see if ORACLE_HOME is in use
log_console " "
fuser $ORACLE_HOME/bin/*
if [ $? -eq 1 ]; then
  log_console "Oracle Home $ORACLE_HOME is not is use continuing with home drop......"
else
  log_console "Oracle Home $ORACLE_HOME is in use by the following processes:"
  fuser -v $ORACLE_HOME/bin/* | tee -a $LOGFILE
  log_console "Please ensure all databases/listeners are not using oracle home $ORACLE_HOME"
fi

# Check to see if a database is defined in ORATAB with ORACLE_HOME 
log_console " "
case `grep  $PSU/ /etc/oratab | wc -l` in
0) remove_home
   update_oratab
   ;;
1) if [ $PSU = `grep $PSU/ /etc/oratab | cut -d : -f1` ] ; then
    remove_home
    update_oratab
  else
    log_console "There is a database entry in the ORATAB using Oracle Home  $ORACLE_HOME"
    log_console "Remove the entry before dropping the ORACLE_HOME"
    exit 1
  fi
  ;;
*) log_console "There are multiple ORATAB entries using $ORACLE_HOME, remove the database entries before dropping the home"
   exit 1
  ;;
esac
 
#if [  `grep  $PSU /etc/oratab | wc -l`  -lt  2 ] ; then
#  if [ $PSU = `grep $PSU /etc/oratab | cut -d : -f1` ] ; then
#    remove_home
#    update_oratab
#  else
#    log_console "There is a database entry in the ORATAB using Oracle Home  $ORACLE_HOME"
#    log_console "Remove the entry before dropping the ORACLE_HOME"
#    exit 1
#  fi
#else
#  log_console "There are multiple ORATAB entries using $ORACLE_HOME, remove the database entries before dropping the home"
#  exit 1
#fi

log_console " "
log_console "Drop of ORACLE_HOME $ORACLE_HOME  complete on  `uname -svrn` at `date` using $0 "
exit 0

