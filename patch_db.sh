#!/bin/bash
##############################################################################################################################################################
#  patch_db.sh is executed to patch database 
#  This script will patch both the primary and any standby databases thate are enabled
#  To prevent  standby databases from being patched by this ecript diable log_transport on the primary database.
#
#  usage: $ . patch_db.sh  <dbms_patched_version> <target_db_name>  
#
#
#  Maintenance Log:
#  version 1.0 06/2015      R. Ryan     New Script 
#  version 1.1 08/2015      R. Ryan     fixed format of pre patch patch registry query 
#  version 1.2 10/2015      R. Ryan     fixed typo in listener config logic
#  version 2.0 10/2015      R. Ryan     Added functionality to update OEM with new ORACLE_HOME value
#  version 2.1 10/2015      R. Ryan     Corrected issue with JAVA location when rpm jdk-7-linux-x64.rpm is not installed
#  version 3.0 11/2015      R. Ryan     Added dataguard support
#  version 3.1 03/15/2016   R. Ryan     Added oracle_home symbolic link switch
#  version 3.2 03/30/2016   R. Ryan     corrected  symbolic link check
#  version 3.3 06/13/2016   R. Ryan     Include update to rman snapshot controlfile configuration to point to new ORACLE_HOME
#  version 3.4 09/27/2016   R. Ryan     added sqlplath assignment to avoid environmental issues, moved log files to the logs dir.
#  version 3.5 10/06/2016   R. Ryan     Corrected mv dbs file issues when there is a SID containing another SID
#  version 3.6 10/06/2016   R. Ryan     added sourcing of bash_profile to avoid JAVA_HOME sqlpath and RCATDB issues
#  version 3.7 01/23/2016   R. Ryan     removed default JAVA_HOME of /usr/java/default, always use $ORACLE_HOME/jdk
#  version 3.8 03/14/2016   R. Ryan     Diaply ORACLE_HOME values pre and post emcli updates for the database and listener
#  version 3.9 03/14/2016   R. Ryan     Suspend Jobs prior to patching and resume them when complete.
#  version 3.10 03/14/2016  R. Ryan     updated listener srvctl env with new TNS_ADMIN value.
#  version 3.11 05/07/2018  R. Ryan     Modified script to use DB_UNIQUE_NAME from database when moving DBS files to avoid issues with non-standard unique names.
#  version 4    05/30/2019  R. Ryan     Added support for Active Data Guard Standby databases. 
#  version 4.1  09/26/2019  R. Ryan     Copied extproc.ora to new oracle home to support databases using Voltage 
#  version 5.0  01/16/2020  R. Ryan     Extended Support for container databases.
#  version 5.1  02/11/2020  R. Ryan     Corrected defect introduced with the additioin of the TNS_ADMIN variable to oraenv. The script was modifying the
#                                       current release listener.ora instead of the new.
#  version 5.2  10/30/2020  R. Ryan     Set the RCATPASS variable since it was removed from oraenv
#  version 6.0  01/19/2021  R. Ryan     Modified script to accomodate new joint CVS/Aetna standard
#
################################################################################################################################################################
# Function : Log message to syslog and console
echo "the patch_db.sh script has been replaced by ansible, please execute the patch_db action in the ans_ent_oracle_install jenkins pipeline to patch your database"
exit 0
