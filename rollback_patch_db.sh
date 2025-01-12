#!/bin/bash
##################################################################################################################################################################
#  rollback_patch_db.sh is executed to rollback to a previous psu release level 
#
#  usage: $ . rollback_patch_db.sh  <dbms_rollback_patch_version> <target_db_name>  
#
#
#  Maintenance Log:
#  version 1.0 11/2015      R. Ryan     New Script 
#  version 1.1 03/15/2016   R. Ryan     added oracle home sybolic link switch
#  version 1.2 03/30/2016   R. Ryan     corrected check for sybolic link 
#  version 1.3 06/13/2016   R. Ryan     included update to RMAN snapshot control file configuration to point to new ORACLE_HOME 
#  version 1.4 09/27/2016   R. Ryan     added sqlplath assignment to avoid environmental issues, moved log files to the logs dir. 
#  version 1.5 10/06/2016   R. Ryan     corrected issue with dbs file moves when a SID contains another SID 
#  version 1.6 11/14/2016   R. Ryan     added sourcing of bash_profile to avoid JAVA_HOME sqlpath and RCATDB issues 
#  version 1.7 01/31/2017   R. Ryan     Copy only patch directories located in sqlpatch instaed of the whole sqlpatch directory 
#  version 1.8 02/16/2017   R. Ryan     updated listener srvctl env with new TNS_ADMIN value.
#  version 1.9 05/07/2018   R. Ryan     Modified script to use DB_UNIQUE_NAME from database when moving DBS files to avoid issues with non-standard unique names.
#  version 2   05/30/2019   R. Ryan     Added support for Active Dataguard standby databases.
#  version 2.1 09/26/2019   R. Ryan     Copied extproc.ora to new oracle home to support databases using Voltage
#  version 3.0 01/16/2020   R. Ryan     Extended support to container databases
#  version 3.1  02/11/2020  R. Ryan     Corrected defect introduced with the additioin of the TNS_ADMIN variable to oraenv. The script was modifying the
#                                       cerrent release listener.ora instead of the new.
#  version 3.2  10/30/2020  R. Ryan     Set the RCATPASS variable since it was removed from oraenv
#  version 4.0  01/19/2021  R. Ryan     Modified script to accomodate new joint CVS/Aetna standard
#  version 4.1  01/19/2021  R. Ryan     Corrected defect when retrieving scripts directory from the standby server
#################################################################################################################################################################
# Function : Log message to syslog and console
echo "the rollback_patch_db.sh script has been replaced by ansible, please execute the patch_db action in the ans_ent_oracle_install jenkins pipeline to patch your database"
exit 0
