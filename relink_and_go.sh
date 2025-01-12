#!/bin/bash
#
# Copyright (c) 2001, 2013, Oracle and/or its affiliates. All rights reserved.
#
# relink_and_go.sh  - Used to relink and start oracle services on reboot if HAS is disabled
# This script is invoked by the rc system.
#
# Note:
#   For security reason,  all cli tools shipped with Clusterware should be
# executed as HAS_USER in init.ohasd and ohasd rc script for SIHA. (See bug
# 9216334 for more details)
#
#   Maintenance Log
#        06/2015	R. Ryan     Modifiied script to recognize an OMS home and to execute root.sh -silent  if encountered.
#                                   TEE'd the output of root.sh to the relink_and_go log
#                                   Checked to ensure relink command exists and is executable in each oracle home.
#
#        10/2015        R. Ryan     Added a bounce of HAS to pick up the correct MEMLOC limits to support huge pages.       
#        03/28/2017     R. Ryan     Added GI patching.       
#        08/16/2017     R. Ryan     Added sleeps to avoid file in use error during GI patching.       
#                                   Modified Disk space check to work with RHEL 6 as well as RHEL 7
#        11/20/2019     R. Ryan     Modified script for 18c. Refer to note 1536057.1 for GI relink procedures.
#                                   Modified script to relink unused GI homes, support multiple versions of GI.
#                                   Modified script to execute GI upgrade if a later release installation is found.
#        02/08/2019     R.Ryan      Modified script to stop all databases after HAS statartup -noaautostart during upgrade process.
#                                   The upgrade requires HAS and ASM to be up but all other services down.  Starting ASM causes
#                                   all databases to start.  Executing crsctl stop res -h "TYPE = ora.database.type" disables databases
#                                   and prevents them from starting with the ASM start.
#        07/19/2019     R. Ryan     Modify script to capture GI unlock and post patch output in the script log. 
#        06/03/2020     R. Ryan     Save oratab and put it back after relink/patch activities to avoid oratab being corrupted
#        01/06/2021     R. Ryan     Accomodate new VM build standard.
#        04/22/2022     R. Ryan     Removed GI patch and upgrade functionality. These functions are replaced by Ansible.

######### Shell functions #########
# Function : Log message to syslog and console
log_console () {
  $ECHO "$*" | tee -a $LOGDIR/relink_and_go_$DATEVAR.out
  $LOGMSG "$*"
}

tolower_host()
{
  #If the hostname is an IP address, let hostname
  #remain as IP address
  H1=`$HOSTN`
  len1=`$EXPRN "$H1" : '.*'`
  len2=`$EXPRN match $H1 '[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*'`

  # Strip off domain name in case /bin/hostname returns
  # FQDN hostname
  if [ $len1 != $len2 ]; then
   H1=`$ECHO $H1 | $CUT -d'.' -f1`
  fi
  
  $ECHO $H1 | $TR '[:upper:]' '[:lower:]'
}

# Invoke crsctl as root in case of clusterware, and HAS_USER in case of SIHA.
# Note: Argument with space might be problemactic (my_crsctl 'hello world')
my_crsctl()
{
  if [ $HAS_USER = "root" ]; then
    $CRSCTL $*
  else
    $SU $HAS_USER -c "$CRSCTL $*"
  fi
}

my_srvctl()
{
  if [ $HAS_USER = "root" ]; then
    $SRVCTL $*
  else
    $SU - $HAS_USER -c "$SRVCTL $*"
  fi
}

my_emcli()
{
  $SU - $HAS_USER -c "$EMCLI $*"
}
###################################

######### Instantiated Variables #########
source ~oracle/std.env
DATEVAR=$(date +'%Y%m%d_%s')
LOGDIR=${STD_DBMS_DIR}/app/oracle/local/logs

export ORA_CRS_HOME=`grep  '^+ASM' /etc/oratab | cut -d: -f2`
export GI_VERSION=`echo $ORA_CRS_HOME | tr -d . | cut -d / -f7`
export LATEST_GI_VERSION=`ls -ld $STD_GRID_DIR/app/oracle/product/*/grid | cut -d / -f7 | cut -d . -f1 | sort -nr | head -n1`
export CURRENT_GI_VERSION=`echo $ORA_CRS_HOME | cut -d / -f7 | cut -d . -f1`
export UPGRADE_GI_HOME=$STD_GRID_DIR/app/oracle/product/${LATEST_GI_VERSION}.0.0/grid
export ORATAB=/etc/oratab

# Definitions
HAS_USER=$STD_HAS_USER
ORA_USER=$STD_ORA_USER
SCRBASE=/etc/oracle/scls_scr
PROG="ohasd"


#limits
CRS_LIMIT_CORE=unlimited
CRS_LIMIT_MEMLOCK=unlimited
CRS_LIMIT_OPENFILE=%CRS_LIMIT_OPENFILE%
##########################################

######### CLI tools #########
HOSTN=/bin/hostname
ECHO=/bin/echo
SLEEP=/bin/sleep
BASENAME=/bin/basename
RMF="/bin/rm -f"
HOSTN=/bin/hostname
TOUCH=/bin/touch
SU=/bin/su
EXPRN=/usr/bin/expr
CUT=/usr/bin/cut
CAT=/bin/cat
GREPX="/bin/grep -x"
LOGMSG="/bin/logger -puser.err"
LOGERR="/bin/logger -puser.alert"
MKDIR=/usr/bin/mkdir
CHMOD=/usr/bin/chmod
CHOWN=/usr/bin/chown
DIRNAME=/usr/bin/dirname
NAMEDPIPE=/var/tmp/.oracle/npohasd

# Location to TR differs in diff. platforms.
TR=/bin/tr
#solaris on amd has issue with /bin/tr
[ 'SunOS' = `/bin/uname` ] && TR=/usr/xpg4/bin/tr 
#on linux tr is at /usr/bin/tr
[ 'Linux' = `/bin/uname` ] && TR=/usr/bin/tr

CRSCTL=$ORA_CRS_HOME/bin/crsctl
SRVCTL=$ORA_CRS_HOME/bin/srvctl
EMCLI=$STD_DBMS_DIR/app/oracle/product/emcli/emcli
#############################

# How long to wait (in seconds) before rechecking a dependency,
# and printing out messages about it.
DEP_CHECK_WAIT=60


MY_HOST=`tolower_host`

PLATFORM=`/bin/uname`
case $PLATFORM in
  Linux)
    LOGGER="/usr/bin/logger"
    if [ ! -f "$LOGGER" ];then
    LOGGER="/bin/logger"
    fi
    LOGMSG="$LOGGER -puser.err"
    LOGERR="$LOGGER -puser.alert"
    SUBSYSFILE="/var/lock/subsys/ohasd"
    CUT="/bin/cut"
    MKDIR=/bin/mkdir
    CHMOD=/bin/chmod
    CHOWN=/bin/chown
    ;;
  HP-UX)
    NAMEDPIPE=/tmp/.oracle/npohasd
    ;;
  SunOS)
    ;;
  AIX)
    NAMEDPIPE=/tmp/.oracle/npohasd
    ;;
  OSF1)
    ;;
  *)
    $ECHO "ERROR: Unknown Operating System"
    exit -1
    ;;
esac

#bug10327228 - To create .oracle directory if it does not exist

NAMEDPIPE_DIR=`$DIRNAME $NAMEDPIPE`

if [ ! -d $NAMEDPIPE_DIR ]
then
  $MKDIR -p  $NAMEDPIPE_DIR
  $CHMOD 01777 $NAMEDPIPE_DIR 
  $CHOWN root  $NAMEDPIPE_DIR 
fi


start_stack()
{
    
  # see init.ohasd.sbs for a full rationale
  case $PLATFORM in
  Linux) 
      # MEMLOCK limit is for Bug 9136459
      ulimit -l $CRS_LIMIT_MEMLOCK
      ulimit -c $CRS_LIMIT_CORE
#     ulimit -n $CRS_LIMIT_OPENFILE
      ;;
  *) 
      ulimit -c $CRS_LIMIT_CORE
      ulimit -n $CRS_LIMIT_OPENFILE
      ;;
  esac

  # enable HA by default on most unix platforms
  case $PLATFORM in
    Linux)
      # touch /var/lock/subsys/ohasd so that the shutdown
      # scripts get called during shutdown time (refer bug 8740030)
      $TOUCH $SUBSYSFILE
      GIPCD_PASSTHROUGH=false
      export GIPCD_PASSTHROUGH
      ;;
    HP-UX)
      GIPCD_PASSTHROUGH=false
      export GIPCD_PASSTHROUGH
      ;;
    SunOS)
      GIPCD_PASSTHROUGH=false
      export GIPCD_PASSTHROUGH
      ;;
    AIX)
      GIPCD_PASSTHROUGH=false
      export GIPCD_PASSTHROUGH
      ;;
    OSF1)
      ;;
  esac

  $ECHO "Starting $PROG: "

  AUTOSTARTFILE=$SCRBASE/$MY_HOST/$HAS_USER/ohasdstr

  # Wait until it is safe to start CRS daemons. Wait for 10 minutes for 
  # filesystem to mount (if crs is enabled). 
  # Print message to syslog and console.

  crsenabled=false
  if [ -r $AUTOSTARTFILE ]
  then
    case `$CAT $AUTOSTARTFILE` in
      enable*)
        crsenabled=true
        log_console ""
    esac
  fi

  if $crsenabled
  then
    works=true
    for minutes in 10 9 8 7 6 5 4 3 2 1
    do
      if [ ! -r $CRSCTL ] 
      then
        works=false
        log_console "Waiting $minutes minutes for filesystem containing $CRSCTL."
        $SLEEP $DEP_CHECK_WAIT
      else
        works=true
        break 
      fi
    done

    if [ ! $works ]
    then
      log_console "Fatal Error :: Timed out waiting for the filesystem containing $CRSCTL."
      log_console "Oracle Grid Infrastructure not able to access filesystem containing $CRSCTL."
      log_console "Fix the problem and issue command 'crsctl start has' as $HAS_USER user to start Oracle Grid Infrastructure."
      exit 1
    fi
  else
    $LOGERR "Not waiting for filesystem containing $CRSCTL because Oracle HA daemon is not enabled." 
  fi

  if [ -r $AUTOSTARTFILE ]
  then
    case `$CAT $AUTOSTARTFILE` in
      enable*)
        log_console "Oracle HA daemon is enabled for autostart - No Relink Actions to take." 
        chown oracle $LOGDIR/relink_and_go_$DATEVAR.out
        ;;
      disable*)
        log_console "Oracle HA daemon is disabled for autostart - Starting relink of oracle software." 
        log_console "================================================================================"
        chown oracle $LOGDIR/relink_and_go_$DATEVAR.out
        chmod 775 $LOGDIR/relink_and_go_$DATEVAR.out
        if [ -r /usr/local/bin/oraenv ]
        then
          cp /usr/local/bin/oraenv /usr/local/bin/oraenv.bak
        fi
        for i in `egrep -v '^#|^$|+ASM|agent' ${ORATAB}| cut -d: -f2| sort -u`
          do
            if [ -x $i/bin/relink ]
            then
              log_console " "
              log_console "Starting Relink of $i"
              log_console " "
              if [ `echo $i | cut -d / -f2` == $STD_GRID_DIR ]; then
                $SU - $HAS_USER -c "export ORACLE_HOME=$i; $i/bin/relink all" | tee -a $LOGDIR/relink_and_go_$DATEVAR.out
                log_console "Relink of $i complete"
                log_console " skipping root.sh for unused GI home"
              else
                $SU - $ORA_USER -c "export ORACLE_HOME=$i; $i/bin/relink all" | tee -a $LOGDIR/relink_and_go_$DATEVAR.out
                log_console "Relink of $i complete"
                log_console "Executing $i/root.sh"
                $i/root.sh | tee -a $LOGDIR/relink_and_go_$DATEVAR.out
                log_console "$i/root.sh complete"
              fi
              log_console " "
              log_console "================================================================================"
            else
              log_console "$i/bin/relink does not exist or is not executable - skipping relink of this oracle home"
            fi
          done
        log_console " "
        log_console "Relink of Oracle DBMS and unused GI homes are complete" 
        cp /etc/oratab /etc/oratab.bak
        log_console " "
        log_console "Starting relink of in use Oracle Grid Infrastructure Home" 
        mv $ORA_CRS_HOME/rdbms/lib/config.o $ORA_CRS_HOME/rdbms/lib/config.o_BAK
        $ORA_CRS_HOME/crs/install/roothas.sh -unlock | tee -a $LOGDIR/relink_and_go_$DATEVAR.out
        $SU - $HAS_USER -c "$ORA_CRS_HOME/bin/relink all" | tee -a $LOGDIR/relink_and_go_$DATEVAR.out
        log_console "Relink of Oracle Grid Infrastructure Home complete" 
        log_console " "
        log_console "Performing Oracle Grid Infrastructure root actions and startup" 
        $ORA_CRS_HOME/crs/install/roothas.sh -postpatch | tee -a $LOGDIR/relink_and_go_$DATEVAR.out
        my_crsctl disable has | tee -a $LOGDIR/relink_and_go_$DATEVAR.out
        sleep 120
        log_console "Performing a restart of HAS to pickup correct MEMLOC limits to support Huge Pages and apply PSU patches"
        $SU - $HAS_USER -c "crsctl stop has" | tee -a $LOGDIR/relink_and_go_$DATEVAR.out
        sleep 120
        $SU - $HAS_USER -c "crsctl start has" | tee -a $LOGDIR/relink_and_go_$DATEVAR.out
        log_console "Oracle Grid Infrastructure startup complete"
        log_console "========================================================================="
        log_console " "
        if [ -r /usr/local/bin/oraenv.bak ]
        then
          cp -p /usr/local/bin/oraenv.bak /usr/local/bin/oraenv
          chown oracle:dba /usr/local/bin/oraenv
        fi
        if [ -r /etc/oratab.bak ]
        then
          cp -p /etc/oratab.bak /etc/oratab
          chown oracle:dba /etc/oratab
          mv /etc/oratab.bak /etc/oratab.$DATEVAR
          chown oracle:dba /etc/oratab.$DATEVAR
        fi
        chown oracle $LOGDIR/relink_and_go_$DATEVAR.out
        ;;
      *)
        $LOGERR "Oracle HA daemon is disabled by damaged install."
        $LOGERR "Unexpected settings found in $AUTOSTARTFILE."
        ;;
    esac
  else
      # If the SCR directory does not exist, then either the user changed
      # their hostname, or they wiped sections of the disk. 
      if [ ! -d "$SCRDIR" ]
      then
        $LOGERR "Oracle Cluster Ready Services startup disabled."
        $LOGERR "Could not access $AUTOSTARTFILE."
      else
        $LOGERR "Oracle Cluster Ready Services is disabled by damaged install."
        $LOGERR "Could not access $AUTOSTARTFILE."
      fi
  fi
}


# See how we were called.
case "$1" in
  start)
    start_stack
    ;;
esac

exit 0;
