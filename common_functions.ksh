#!/bin/ksh

function list_oratab
{
   typeset listfield=1
   typeset yesno="Y"

   while getopts :npz OPTION $*
   do
      case $OPTION in
         n)  listfield=1
             ;;
         p)  listfield=2
             ;;
         z)  yesno="N"
             ;;
         ?)  echo "usage: list_oratab [-n|-p] [-z]"
             echo "   n - list name"
             echo "   p - list path"
             echo "   p - show entries with 'N' rather than 'Y'"
             return
             ;;
        esac
   done

   awk -v "listfield=$listfield" -v "yesno=$yesno" -F":" '!/^#.*/ {if ($3 == yesno) {print $listfield}}' /etc/oratab 
}

function list_orabases
{
   typeset ORACLE_HOME
   for l in `list_oratab -p`
   do
      ORACLE_HOME=$l
      if [ -x $ORACLE_HOME/bin/orabase ]
      then
         $ORACLE_HOME/bin/orabase
      fi
   done | sort -u
}

function list_adr_bases
{ 
   list_orabases > $oTEMPDIR/list_adr_bases.$$
   for i in `list_running -i`
   do
     oenv $i
     show_parameter diagnostic_dest >> $oTEMPDIR/list_adr_bases.$$
   done 

   cat $oTEMPDIR/list_adr_bases.$$ | sort -u 
   rm -f $oTEMPDIR/list_adr_bases.$$
}

function list_adr_homes
{ 
   typeset adr_base=$1
   if [ -z "$adr_base" ]
   then
      echo "Usage: list_adr_homes <adr_base path>"
      return 1
   fi

   adrci exec = "set base $adr_base ; show homes;"| tail -n "+2" 
   
}

function list_running
{
   while getopts :li OPTION $*
   do
      case $OPTION in
         i) ps -e -o args | grep ora_pmon | grep -v grep | awk '{print substr($1,10)}'
            ;;
         l) ps -e -o args | grep tnslsnr | grep -v grep | awk '{print $2}'
             ;;
         ?)  echo "usage: list_running [-l|-i]"
             echo "   l - listeners"
             echo "   i - instances"
             return
             ;;
        esac
   done
}

function show_instance_info
{
   echo "Diagnostic Dest:" `show_parameter diagnostic_dest`
   echo "Alert Log Dir:" `show_parameter background_dump_dest`
   echo "Archivelog Dest:" `show_parameter log_archive_dest_1`
}

function show_parameter
{
   typeset pname=$1
   sqlplus -S -L "/ as sysdba" <<-EOF
	whenever sqlerror exit failure
	set heading off
	set linesize 2048
	set feedback off
	set pagesize 0
	select value from v\$parameter where name='$pname';
	exit;
	EOF
   if [ $? -ne 0 ]
   then
      return 1
   fi
   return 0
}

function show_listener_parameter
{
   typeset lname=$1
   typeset pname=$2

   lsnrctl <<-EOF | awk '/set to/ {print $6}'
	set current_listener $1
	show $2
	EOF
   if [ $? -ne 0 ]
   then
      return 1
   fi
   return 0
}

oenv()
{
   
   typeset orig_sid=$ORACLE_SID
   typeset orig_home=$ORACLE_HOME
   typeset orig_base=$ORACLE_BASE
   typeset orig_path=$PATH
   typeset orig_ld_lib_path=$LD_LIBRARY_PATH

   # Just use current Oracle SID if not passed 
   if [ $# -ge 1 ]
   then
      export ORACLE_SID=$1
   fi

   if [ -z "$ORACLE_SID" ]
   then
      echo "ORACLE_SID not set"
   fi

   export ORACLE_HOME=`awk -v"iname=$ORACLE_SID" -F":" '!/^#.*/ {if ($1 == iname) {print $2}}' /etc/oratab`

   if [ ! -d "$ORACLE_HOME" ]
   then
      echo "Oracle Home not found for $ORACLE_SID: $ORACLE_HOME"
      ORACLE_SID=$orig_sid; export ORACLE_SID
      ORACLE_HOME=$orig_home; export ORACLE_HOME
      return 1
   fi

   ### Borrowed from oraenv - replace the old ORACLE_HOME in the path
   case "$orig_home" in 
        "") orig_home=$PATH ;;
   esac

   case "$PATH" in 
        *$orig_home/bin*)     PATH=`echo $PATH | \
                              sed "s;$orig_home/bin;$ORACLE_HOME/bin;g"` ;;
        *$ORACLE_HOME/bin*)   ;;
        *:)                   PATH=${PATH}$ORACLE_HOME/bin: ;;
        "")                   PATH=$ORACLE_HOME/bin ;;
        *)                    PATH=$PATH:$ORACLE_HOME/bin ;;
   esac
                                                                               
   export PATH
   case ${LD_LIBRARY_PATH:-""} in
        *$orig_home/lib*)   LD_LIBRARY_PATH=`echo $LD_LIBRARY_PATH | \
                            sed "s;$orig_home/lib;$ORACLE_HOME/lib;g"` ;;
        *$ORACLE_HOME/lib*) ;;
        "")                 LD_LIBRARY_PATH=$ORACLE_HOME/lib ;;
        *)                  LD_LIBRARY_PATH=$ORACLE_HOME/lib:$LD_LIBRARY_PATH ;;
   esac
                                                                            
   export LD_LIBRARY_PATH                                                      
   export ORACLE_BASE=`$ORACLE_HOME/bin/orabase 2>/dev/null`
}

### Set some common environment variables
oTEMPDIR=/tmp
