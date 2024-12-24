#!/bin/sh

# new standard
# Set To Script Directory
SCRDIR="/oradb/app/oracle/local/scripts/HRP_upgrade"
SCR=/oradb/app/oracle/local/scripts




# Change To Script Directory
cd ${SCRDIR}



# Confirm Input Parameter
if [ ${#} -ne 1 ] ; then
   echo "Must Enter Input Database Name"
   exit 1
fi

# Set To Input Database Name
DBName=$1
typeset -u DBName



# Set Oracle Environment
PATH=/usr/bin:/usr/sbin:/etc:/usr/local/bin:/bin
export ORAENV_ASK=NO
export ORACLE_SID=${DBName}
export ORACLE_HOME=`awk -F: "/^${ORACLE_SID}:/ {print \\$2; exit}" /etc/oratab 2>/dev/null`
export PATH=${ORACLE_HOME}:${PATH}
. ${ORACLE_HOME}/bin/oraenv > /dev/null 2>&1


# Remove From Previous Run
if [ -f deploy_DW_views.out ] ; then
   rm deploy_DW_views.out
fi


# execute lock
sqlplus -s <<EOF
/ as sysdba
whenever sqlerror exit failure;
spool deploy_DW_views.out
@step2_create_ACCOUNT_HISTORY_FACT_view_PRD.sql
@step3_create_ALL_MEMBER_HISTORY_FACT_view.sql
@step3_create_MEMBER_HISTORY_FACT_view.sql
@step4_create_AUTH_FACT.sql
@step4_create_MBR_PHI_LGL_REPRESENTATIV_MASK_FACT_view.sql
@step4_create_MEMBER_HIST_FACT_TO_PHYS_ADDR_MASK_view.sql
@step4_create_MEMBER_HIST_FACT_TO_RESP_PRSN_mask_view.sql
@step4_create_member_hist_fct_to_contct_info_mask_view.sql
@step4_create_OTHER_NAME_USED_MASK_FACT_view.sql
@step4_create_PREMIUM_PAYMENT_ROSTER_MASK_FACT_view.sql
@step5_create_MBR_PHI_LGL_RPRSNTV_PHONE_MASK_FACT_view.sql
spool off
EOF



# Obtain SQLPlus Return Code
SQLRC=$?

# If Error Encountered
if [ $SQLRC -ne 0 ] ; then
   echo
   echo "Error Encountered deploying DW Views in Database ${DBName}"
   echo
   exit 1
fi


# Change Permissions
#chmod 600 deploy_DW_views.out
