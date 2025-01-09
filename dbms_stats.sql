
select owner, table_name, last_analyzed
from dba_tables
where owner in ('PROD') and to_char(last_analyzed, 'mm/dd/yyyy') = '06/18/2020'
ORDER BY last_analyzed desc




exec dbms_stats.delete_schema_stats(OWNNAME=>'VRSC');
exec dbms_stats.gather_schema_stats(ownname=>'VRSC', method_opt=>'FOR ALL COLUMNS SIZE AUTO' , cascade=>TRUE);

exec dbms_stats.delete_schema_stats(OWNNAME=>'GEMS');
exec dbms_stats.gather_schema_stats(ownname=>'GEMS', method_opt=>'FOR ALL COLUMNS SIZE AUTO' , cascade=>TRUE);


exec dbms_stats.delete_schema_stats(OWNNAME=>'VRSC_ARCHIVE');
exec dbms_stats.gather_schema_stats(ownname=>'VRSC_ARCHIVE', method_opt=>'FOR ALL COLUMNS SIZE AUTO' , cascade=>TRUE);



exec dbms_stats.delete_table_stats('VRSC', 'MCS_SVC_REQ');
EXEC DBMS_STATS.gather_table_stats('VRSC', 'ALARMS_INCOMING_HISTORIES', estimate_percent => 10);
EXEC DBMS_STATS.gather_table_stats('VRSC', 'MCS_PARTS_ACTIVITY',estimate_percent => 20);

EXEC DBMS_STATS.gather_table_stats('VRSC', 'MCS_PART_PRICING',estimate_percent => 20);



exec dbms_stats.export_index_stats('VRSC', 'ALARM_INDEX1', NULL, 'ALARMS_INCOMING');
exec dbms_stats.export_index_stats('VRSC', 'ALL_UNACKNOWLEDGED', NULL, 'ALARMS_INCOMING');
exec dbms_stats.export_index_stats('VRSC', 'MONITOR_CENTER', NULL, 'ALARMS_INCOMING');
exec dbms_stats.export_index_stats('VRSC', 'ALARM_STATUS', NULL, 'ALARMS_INCOMING');
exec dbms_stats.export_index_stats('VRSC', 'ALARM_SITE_ID', NULL, 'ALARMS_INCOMING');
exec dbms_stats.export_index_stats('VRSC', 'ALARM_INC_PK', NULL, 'ALARMS_INCOMING');

exec dbms_stats.export_table_stats('VRSC', 'ALARMS_INCOMING');



EXEC DBMS_STATS.gather_table_stats('VRSC', 'WEB_CUST_ACCOUNT', estimate_percent => 10);

EXEC DBMS_STATS.gather_index_stats('VRSC', 'MTD_INDEX2', estimate_percent => 15);

EXEC DBMS_STATS.gather_table_stats('VRSC', 'CUST_POLL_CMD_RESPONSE', estimate_percent => 10);


EXEC DBMS_STATS.gather_index_stats('VRSC', 'MASTER_TGT_PK',estimate_percent => 75);




Mikes---------->
   exec dbms_stats.gather_table_stats(OWNNAME=>'WKAB10', tabname=>'T_WKAB_LOOKUP', method_opt=> 'FOR ALL COLUMNS SIZE 1', force=>TRUE, no_invalidate=>FALSE);

Mikes as well ----->
exec dbms_stats.gather_table_stats(ownname=>'PIHMS', tabname=>'EMP_UPPER_SUPERVISOR_VW', cascade=>true, no_invalidate=>false);


   exec dbms_stats.gather_index_stats(ownname=>'WKAB10', indname=>'PK_REQUEST',no_invalidate=>false, force=>true);

exec dbms_stats.gather_index_stats(ownname=>'WKAB10', indname=>'T_PERSON_IDX_002', no_invalidate=>false, force=>true);
WKAB10.T_PERSON_IDX_002

exec dbms_stats.gather_table_stats(OWNNAME=>'WKAB10', tabname=>'T_WCP_AUDIT', force=>TRUE, no_invalidate=>FALSE);

exec dbms_stats.gather_table_stats(OWNNAME=>'DRWKAB', tabname=>'WKAB_LOOKUP_MV', force=>TRUE, no_invalidate=>FALSE);


exec dbms_stats.gather_table_stats(OWNNAME=>'DRWKAB', tabname=>'WKAB_A_DIS_CLAIM_MV', force=>TRUE, no_invalidate=>FALSE);

exec dbms_stats.gather_table_stats(ownname=>'PIHMS', tabname=>'EMP_UPPER_SUPERVISOR_VW', cascade=>true, no_invalidate=>false);




select to_char(sysdate, 'MM-DD-YYYY HH:MI:SS AM') as "Start Time" from dual;
exec dbms_stats.gather_table_stats(OWNNAME=>'SYSADM', tabname=>'PS_SJT_PERSON', force=>TRUE, no_invalidate=>FALSE);
select to_char(sysdate, 'MM-DD-YYYY HH:MI:SS AM') as "End Time" from dual;


select to_char(sysdate, 'MM-DD-YYYY HH:MI:SS AM') as "Start Time" from dual;
exec dbms_stats.gather_table_stats(OWNNAME=>'SYSADM', tabname=>'PS_SET_CNTRL_REC', force=>TRUE, no_invalidate=>FALSE);
select to_char(sysdate, 'MM-DD-YYYY HH:MI:SS AM') as "End Time" from dual;


exec dbms_stats.gather_schema_stats(ownname=>'SYSADM', method_opt=>'FOR ALL COLUMNS SIZE AUTO' , cascade=>TRUE,no_invalidate=>false);



exec dbms_stats.gather_table_stats(ownname=>'SYSADM', tabname=>'PS_PTUALTRECFLDDAT', cascade=>true, no_invalidate=>false);
exec dbms_stats.gather_table_stats(ownname=>'SYSADM', tabname=>'PS_PTRECFIELDDB', cascade=>true, no_invalidate=>false);
exec dbms_stats.gather_table_stats(ownname=>'SYSADM', tabname=>'PS_PTDBFIELD', cascade=>true, no_invalidate=>false);
exec dbms_stats.gather_table_stats(ownname=>'SYSADM', tabname=>'PS_PTRECDEFN', cascade=>true, no_invalidate=>false);

exec dbms_stats.gather_table_stats(ownname=>'WKAB10', tabname=>'T_REPORT_QUEUE', degree=>2, no_invalidate=>false);
exec dbms_stats.gather_table_stats(ownname=>'WKAB10', tabname=>'T_EMPLOYEE', degree=>2, no_invalidate=>false);

exec dbms_stats.gather_table_stats(ownname=>'WKAB10', tabname=>'T_REPORT_TYPE', degree=>2, no_invalidate=>false);
exec dbms_stats.gather_table_stats(ownname=>'WKAB10', tabname=>'T_PERSON', degree=>2, no_invalidate=>false);
exec dbms_stats.gather_table_stats(ownname=>'WKAB10', tabname=>'T_WKAB_LOOKUP', degree=>2, no_invalidate=>false);



degree => 2

exec dbms_stats.gather_table_stats(ownname=>'SYSADM', tabname=>'TEMP_DATAMASK', degree=>2, no_invalidate=>false);

exec dbms_stats.gather_table_stats(ownname=>'SYSADM', tabname=>'PS_KNS_VW_PAYMENTS', degree=>2, no_invalidate=>false);

exec dbms_stats.gather_table_stats(ownname=>'PIHMS', tabname=>'EMP_EMPLOYEE', degree=>2, no_invalidate=>false);

exec dbms_stats.gather_table_stats(ownname=>'PIHMS', tabname=>'EJB_EMP_JOB', degree=>2, no_invalidate=>false);
                      
                 

exec dbms_stats.gather_table_stats(ownname=>'PROD_DW', tabname=>'TMPCACHED_CURRENTCLAIMS', degree=>2, no_invalidate=>false);     

exec dbms_stats.gather_table_stats(ownname=>'PROD_DW', tabname=>'MEDICARE_HICN_INFO_FACT', degree=>2, no_invalidate=>false);   


exec dbms_stats.gather_table_stats(ownname=>'SYSADM', tabname=>'PSTREEDEFNLANG', degree=>2, no_invalidate=>false);

exec dbms_stats.gather_table_stats(ownname=>'SYSADM', tabname=>'PSTREEBRANCH', degree=>2, no_invalidate=>false);

exec dbms_stats.gather_table_stats(ownname=>'SYSADM', tabname=>'PSTREELEVEL', degree=>2, no_invalidate=>false);

exec dbms_stats.gather_table_stats(ownname=>'SYSADM', tabname=>'PSTREESELCTL', degree=>2, no_invalidate=>false);

exec dbms_stats.gather_table_stats(ownname=>'SYSADM', tabname=>'PSTREELEAF', degree=>2, no_invalidate=>false);

exec dbms_stats.gather_table_stats(ownname=>'SYSADM', tabname=>'PSTREEPROMPT', degree=>4, cascade=>TRUE, no_invalidate=>false);

----
EXECUTE DBMS_STATS.GATHER_SCHEMA_STATS(ownname => 'PIHMS', estimate_percent => NULL);


---- Latest HE Tom's example

---[?01/?09/?2018 2:00 PM] Schloendorn, Thomas: 
--no
---no_invalidate will invalidate all plans in memory using that table
---in this case I did not want that

-- How to restore stats in case things got worse
--execute DBMS_STATS.RESTORE_TABLE_STATS ('PROD','CLAIM_PAYABLE',sysdate-2); 

exec dbms_stats.gather_table_stats(ownname=>'SYSADM', tabname=>'PSTREEPROMPT', degree=>2);  


from v$sqlarea 
where sql_id = '4s6aabx2d0vq9';


exec dbms_shared_pool.purge ('0000000784D4FE88,1154510537','C');  


dbms_stats.gather_schema_stats('WKAB10');



exec dbms_stats.gather_table_stats(OWNNAME=>'XLA', tabname=>'XLA_AE_LINES_GT', force=>TRUE, no_invalidate=>FALSE);


************ Latest example we used in HEPYPRD ********

exec DBMS_STATS.UNLOCK_SCHEMA_STATS ('PROD');
exec dbms_stats.gather_table_stats(ownname=>'SYSADM', tabname=>'PSTREEPROMPT', degree=>4, cascade=>TRUE, no_invalidate=>false);


***** HEDWPRD ***

PROD_DW.DATE_DIMENSION  - 11/19
PROD_DW.MEMBER_HISTORY_FACT - 11/09
PROD_DW.BENEFIT_PLAN_HISTORY_FACT  - 11/16
PROD_DW.BENEFIT_PLAN_FACT_TO_PLAN_UDT - 9/28
PROD_DW.PLAN_UDT_VALUE - 11/8
PROD_DW.PROVIDER_TAXONOMY - 8/18
PROD_DW.POSTAL_ADDRESS - 12/1
PROD_DW.PRACTITIONER_ROLE_HISTORY_FACT - 12/1
PROD_DW.PRODUCT - 10/15
PROD_DW.CLAIM_LINE_FACT - 12/2
PROD_DW.CLAIM_FACT - 12/2

AE_CUSTOM.AETNA_PLAN_CHANGES - 7/3


exec dbms_stats.gather_table_stats(ownname=>'PROD_DW', tabname=>'CLAIM_FACT', degree=>2, no_invalidate=>false); 

exec dbms_stats.gather_table_stats(ownname=>'AE_CUSTOM', tabname=>'CLAIM_PAYMENTS', degree=>4, no_invalidate=>false); 

exec dbms_stats.gather_index_stats(ownname=>'WKAB10', indname=>'T_PERSON_IDX_002', no_invalidate=>false, force=>true);


exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'BLOB_MEMBER_SELECTIONS', degree=>2, no_invalidate=>false);

exec dbms_stats.gather_table_stats(ownname=>'WKAB10', tabname=>'t_script_instance_detail', degree=>2, no_invalidate=>false); 


*** currently in crontab

##exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'CVC_INSTANCE_CONTEXT', degree=>4, no_invalidate=>false, cascade=>true);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'CVC_INSTANCE_CONTEXT', degree=>4, cascade=>true);

30 04 * * 0-6 /home/oracle/tls/stats/gather_supplier_stats.sh HEPYPRD > /dev/null 2>&1





00 13 * * * /home/oracle/tls/stats/gather_20_3_stats.sh HEPYSTS

00 13 * * * /bin/sh /orahome/u01/app/oracle/local/scripts/crontab_backup.sh


prompt Gathering Stats on Table PROD.ACCOUNT (Table 1 of 33);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'ACCOUNT', degree=>4, cascade=>true);
prompt

prompt Gathering Stats on Table PROD.ADDRESS_INFORMATION (Table 2 of 33);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'ADDRESS_INFORMATION', degree=>4, cascade=>true);
prompt

prompt Gathering Stats on Table PROD.AUTHORIZATION_RECEIVED (Table 3 of 33);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'AUTHORIZATION_RECEIVED', degree=>4, cascade=>true);
prompt

prompt Gathering Stats on Table PROD.BENEFIT_PLAN (Table 4 of 33);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'BENEFIT_PLAN', degree=>4, cascade=>true);
prompt


prompt Gathering Stats on Table PROD.CLAIM_PAYABLE (Table 5 of 33);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'CLAIM_PAYABLE', degree=>4, cascade=>true);
prompt

prompt Gathering Stats on Table PROD.CLAIM_TOTAL (Table 6 of 33);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'CLAIM_TOTAL', degree=>4, cascade=>true);
prompt

prompt Gathering Stats on Table PROD.CODE_ENTRY (Table 7 of 33);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'CODE_ENTRY', degree=>4, cascade=>true);
prompt

prompt Gathering Stats on Table PROD.CONSOLIDATED_CLAIM (Table 8 of 33);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'CONSOLIDATED_CLAIM', degree=>4, cascade=>true);
prompt

prompt Gathering Stats on Table PROD.CORRESPONDENCE_INFORMATION (Table 9 of 33);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'CORRESPONDENCE_INFORMATION', degree=>4, cascade=>true);
prompt

prompt Gathering Stats on Table PROD.INDIVIDUAL (Table 10 of 33);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'INDIVIDUAL', degree=>4, cascade=>true);
prompt

prompt Gathering Stats on Table PROD.INDIVIDUAL_INFORMATION (Table 11 of 33);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'INDIVIDUAL_INFORMATION', degree=>4, cascade=>true);
prompt

prompt Gathering Stats on Table PROD.INDVL_INFO_X_LANGUAGES (Table 12 of 33);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'INDVL_INFO_X_LANGUAGES', degree=>4, cascade=>true);
prompt

prompt Gathering Stats on Table PROD.LANGUAGE_SPOKEN (Table 13 of 33);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'LANGUAGE_SPOKEN', degree=>4, cascade=>true);
prompt

prompt Gathering Stats on Table PROD.MEMBER_PHYSICAL_ADDRESS (Table 14 of 33);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'MEMBER_PHYSICAL_ADDRESS', degree=>4, cascade=>true);
prompt

prompt Gathering Stats on Table PROD.MEMBERSHIP (Table 15 of 33);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'MEMBERSHIP', degree=>4, cascade=>true);
prompt

prompt Gathering Stats on Table PROD.ORGANIZATION_INFORMATION (Table 16 of 33);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'ORGANIZATION_INFORMATION', degree=>4, cascade=>true);
prompt

prompt Gathering Stats on Table PROD.PAYMENT (Table 17 of 33);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'PAYMENT', degree=>4, cascade=>true);
prompt

prompt Gathering Stats on Table PROD.PERSON_NAME (Table 18 of 33);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'PERSON_NAME', degree=>4, cascade=>true);
prompt

prompt Gathering Stats on Table PROD.PERSON_NAME_NAME_SUFFIX_SUFFIX (Table 19 of 33);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'PERSON_NAME_NAME_SUFFIX_SUFFIX', degree=>4, cascade=>true);
prompt

prompt Gathering Stats on Table PROD.POSTAL_ADDRESS (Table 20 of 33);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'POSTAL_ADDRESS', degree=>4, cascade=>true);
prompt

prompt Gathering Stats on Table PROD.PRACTITIONER (Table 21 of 33);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'PRACTITIONER', degree=>4, cascade=>true);
prompt

prompt Gathering Stats on Table PROD.PRACTITIONER_ROLE (Table 22 of 33);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'PRACTITIONER_ROLE', degree=>4, cascade=>true);
prompt

prompt Gathering Stats on Table PROD.PRODUCT (Table 23 of 33);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'PRODUCT', degree=>4, cascade=>true);
prompt


prompt Gathering Stats on Table PROD.RELATED_MEMBER (Table 24 of 33);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'RELATED_MEMBER', degree=>4, cascade=>true);
prompt

prompt Gathering Stats on Table PROD.SPPL_C_X_OTHR_CORRE_ADDR_LST (Table 25 of 33);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'SPPL_C_X_OTHR_CORRE_ADDR_LST', degree=>4, cascade=>true);
prompt

prompt Gathering Stats on Table PROD.SUBSCRIPTION (Table 26 of 33);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'SUBSCRIPTION', degree=>4, cascade=>true);
prompt

prompt Gathering Stats on Table PROD.SUBSCRIPTION_PLAN_SELECTION (Table 27 of 33);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'SUBSCRIPTION_PLAN_SELECTION', degree=>4, cascade=>true);
prompt

prompt Gathering Stats on Table PROD.SUBSCRIPTION_SELECTIONS (Table 28 of 33);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'SUBSCRIPTION_SELECTIONS', degree=>4, cascade=>true);
prompt

prompt Gathering Stats on Table PROD.SUPPLIER (Table 29 of 33);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'SUPPLIER', degree=>4, cascade=>true);
prompt

prompt Gathering Stats on Table PROD.SUPPLIER_LOCATION (Table 30 of 33);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'SUPPLIER_LOCATION', degree=>4, cascade=>true);
prompt

prompt Gathering Stats on Table PROD.TRANSFORMED_DELIVERED_SERVICE (Table 31 of 33);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'TRANSFORMED_DELIVERED_SERVICE', degree=>4, cascade=>true);
prompt

prompt Gathering Stats on Table PROD.CVC_INSTANCE_CONTEXT (Table 32 of 33);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'CVC_INSTANCE_CONTEXT', degree=>4, cascade=>true);
prompt

prompt Gathering Stats on Table PROD.CVC_STEP (Table 33 of 33);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'CVC_STEP', degree=>4, cascade=>true);
prompt


exec dbms_stats.gather_table_stats(ownname=>'PROD_DW', tabname=>'ACCOUNT_UDT_VALUE', degree=>4, cascade=>true, no_invalidate=>false);



exec dbms_stats.gather_table_stats(ownname=>'PROD_DW', tabname=>'CLAIM_FACT', degree=>2, cascade=>true);




SPPLR_LOC_X_OTHR_ID_LST

exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'SPPL_C_X_OTHR_CORRE_ADDR_LST', degree=>6, cascade=>true);

exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'SPPLR_LOC_X_OTHR_ID_LST',  degree=>6, cascade=>true); --- took forever was killed

exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'SPP_X_OTHR_CORRESP_E_ADDR_LST', degree=>6, cascade=>true);

exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'SPPLR_LOC_X_SPPLR_CLSS',  degree=>6, cascade=>true);


SPP_X_OTHR_CORRESP_E_ADDR_LST
SPPLR_LOC_X_SPPLR_CLSS

--MemberLinkQuery
	exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'PERSON_NAME', no_invalidate=>false, degree=>4, cascade=>true);
	exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'MEMBER_LINK', no_invalidate=>false, degree=>4, cascade=>true);
	exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'individual_information', no_invalidate=>false, degree=>4, cascade=>true);
	exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'rltp_to_subscrb_def', no_invalidate=>false, degree=>4, cascade=>true);
	exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'udt_value_link', no_invalidate=>false, degree=>4, cascade=>true);
        exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'membership', no_invalidate=>false, degree=>4, cascade=>true);
        exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'subscription', no_invalidate=>false, degree=>4, cascade=>true);
        exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'product', no_invalidate=>false, degree=>4, cascade=>true);


Member_link
Membership
Individual_information
Person_name
Product
Subscription
Rltp_to_subcrb_def
Udt_value_link



--OutstandingClaimPayablePayeeAndBankAccounts 
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'payment_cycle', no_invalidate=>false, degree=>4, cascade=>true);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'cycle', no_invalidate=>false, degree=>4, cascade=>true);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'bank_account', no_invalidate=>false, degree=>4, cascade=>true);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'payee', no_invalidate=>false, degree=>4, cascade=>true);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'supplier_location', no_invalidate=>false, degree=>4, cascade=>true);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'payable', no_invalidate=>false, degree=>4, cascade=>true);


--ClaimLinesForSubscription
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'practitioner', degree=>6, cascade=>true);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'diagnosis',  degree=>6, cascade=>true);

exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'CVC_INSTANCE_CONTEXT',  degree=>12, cascade=>true);

exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'tax_entity',  degree=>6, cascade=>true);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'supplier_x_other_id_list',  degree=>6, cascade=>true);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'identification_number',  degree=>6, cascade=>true);
   
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'other_organization_name_used',  degree=>4, cascade=>true);  

exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'supplier_x_other_id_list',  degree=>6, cascade=>true);  

exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'identification_number',  degree=>6, cascade=>true); 

exec dbms_stats.gather_table_stats(ownname=>'PROD_DW', tabname=>'all_member_version_hist_fact',  degree=>6, cascade=>true);   

exec dbms_stats.gather_table_stats(ownname=>'PROD_DW', tabname=>'medicare_hicn_info_fact',  degree=>6, cascade=>true);

exec dbms_stats.gather_table_stats(ownname=>'PROD_DW', tabname=>'postal_address',  degree=>6, cascade=>true);


exec dbms_stats.gather_table_stats(ownname=>'PROD_DW', tabname=>'AUTH_REFERRAL_SERVICE',  degree=>4, cascade=>true);



exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'correspondence_information',  degree=>6, cascade=>true);

exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'address_information',  degree=>6, cascade=>true);


exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'PROCEDURE',  degree=>6, cascade=>true);

exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'drg',  degree=>6, cascade=>true);

exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'service_cost',  degree=>6, cascade=>true);




exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'practitioner',  degree=>4, cascade=>true);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'correspondence_information',  degree=>4, cascade=>true);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'address_information',  degree=>4, cascade=>true);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'postal_address',  degree=>4, cascade=>true);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'individual_information',  degree=>4, cascade=>true);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'other_name_used',  degree=>4, cascade=>true);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'person_name',  degree=>4, cascade=>true);

exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'cvc_instance_context',  degree=>4, cascade=>true);


exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'payable',  degree=>4, cascade=>true);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'outstanding_payable',  degree=>4, cascade=>true);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'claim_payable',  degree=>4, cascade=>true);

exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'other_organization_name_used',  degree=>4, cascade=>true);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'organization_info_x_othr_names',  degree=>4, cascade=>true);

exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'claim_payable',  degree=>2, cascade=>true);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'payee',  degree=>2, cascade=>true);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'payable',  degree=>2, cascade=>true);


exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'BANK_ACCOUNT',  degree=>2, cascade=>true);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'CYCLE',  degree=>2, cascade=>true);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'payment_cycle',  degree=>2, cascade=>true);

exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'subscription',  degree=>3, cascade=>true);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'membership',  degree=>3, cascade=>true);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'member_selections',  degree=>3, cascade=>true);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'member_plan_selection',  degree=>3, cascade=>true);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'mbr_plan_lection_x_date_r_ges',  degree=>3, cascade=>true);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'mbr_plan_selection_date_range',  degree=>3, cascade=>true);


exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'included_payable',  degree=>4, cascade=>true);

exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'OUTSTANDING_PAYABLE',  degree=>4, cascade=>true);

***** Extended stats ***** 
1. Collect regular latest stats

exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'PAYABLE',  degree=>4, cascade=>true);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'OUTSTANDING_PAYABLE',  degree=>4, cascade=>true);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'CLAIM_PAYABLE',  degree=>4, cascade=>true);

exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'PAYMENT_BATCH',  degree=>4, cascade=>true);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'PAYMENT_RUN_DEFINITION',  degree=>4, cascade=>true);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'PAYMENT_CYCLE',  degree=>4, cascade=>true);



exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'SUPPLIER',  degree=>8, cascade=>true);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'ORGANIZATION_INFORMATION',  degree=>8, cascade=>true);

exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'SUPPLIER_LOCATION',  degree=>8, cascade=>true);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'ADDRESS_INFORMATION',  degree=>8, cascade=>true);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'POSTAL_ADDRESS',  degree=>8, cascade=>true);

exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'PAYEE',  degree=>6, cascade=>true);

exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'SPPLR_BNFT_NETWRK_REF',  degree=>6, cascade=>true);
blob_inter_serv_auth

PROD                                  26-MAR-2022 22:27:23   11597630 N
PROD         RECONCILIATION_LINE                      26-MAR-2022 22:21:27    5804287 N
PROD         SPECIALTY_NETWORK_LINK                   12-FEB-2022 06:00:38    1917436 N

--CAP stats
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'RECONCILIATION_LINE',  degree=>8, cascade=>true);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'ATTRIBUTION_LINE',  degree=>8, cascade=>true);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'SPECIALTY_NETWORK_LINK',  degree=>8, cascade=>true);
---

exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'OFFSET_RE_IVABLE_X_RECOUP_NTS',  degree=>6, cascade=>true);

exec dbms_stats.gather_table_stats(ownname=>'PROD_DW', tabname=>'ALL_CLAIM_FACT',  degree=>6, cascade=>true);
exec dbms_stats.gather_table_stats(ownname=>'PROD_DW', tabname=>'CLAIM_LN_FCT_TO_REVIEW_TRIGGER',  degree=>6, cascade=>true);
exec dbms_stats.gather_table_stats(ownname=>'PROD_DW', tabname=>'TRANSACTION_STEP_COMPLETED_FACT',  degree=>6, cascade=>true);


exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'PAYMENT_BATCH',  degree=>6, cascade=>true);

exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'OUTSTANDING_WORKBASKET_MSG_CD',  degree=>4, cascade=>true);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'OUTSTANDING_WORKBASKET',  degree=>4, cascade=>true);


exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'SUPPLIER',  degree=>6, cascade=>true);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'PROVIDER_TAXONOMY',  degree=>6, cascade=>true);
provider_taxonomy



exec dbms_stats.gather_index_stats(ownname=>'PROD', indname=>'FK_CVC_STEP_CVC_STEP', degree=>4, no_invalidate=>false, force=>true);
exec dbms_stats.gather_index_stats(ownname=>'PROD', indname=>'STEP_ACTIVE_LTST_TYP_NM', degree=>4, no_invalidate=>false, force=>true);
*************************************


exec dbms_stats.gather_index_stats(ownname=>'PROD', indname=>'STEP_END_TIME', degree=>4, no_invalidate=>false, force=>true);
exec dbms_stats.gather_index_stats(ownname=>'PROD', indname=>'CVC_STEP', degree=>4, no_invalidate=>false, force=>true);
exec dbms_stats.gather_index_stats(ownname=>'PROD', indname=>'FK_CVC_STEP_CVC_FAILURE_DETAIL', degree=>4, no_invalidate=>false, force=>true);
exec dbms_stats.gather_index_stats(ownname=>'PROD', indname=>'FK_CVC_STEP_CVC_INST_CONTEXT', degree=>4, no_invalidate=>false, force=>true);
exec dbms_stats.gather_index_stats(ownname=>'PROD', indname=>'CVC_STEP_HCC_ID_UPPER', degree=>4, no_invalidate=>false, force=>true);
exec dbms_stats.gather_index_stats(ownname=>'PROD', indname=>'CVC_STEP_IDX', degree=>4, no_invalidate=>false, force=>true);
exec dbms_stats.gather_index_stats(ownname=>'PROD', indname=>'CVC_STEP_LATEST_ID_TYPE_TXT', degree=>4, no_invalidate=>false, force=>true);
exec dbms_stats.gather_index_stats(ownname=>'PROD', indname=>'CVC_STEP_TYPE_ID_ACTIVE', degree=>4, no_invalidate=>false, force=>true);
exec dbms_stats.gather_index_stats(ownname=>'PROD', indname=>'START_TIME_CVC_STEP_LATEST_ID', degree=>4, no_invalidate=>false, force=>true);
exec dbms_stats.gather_index_stats(ownname=>'PROD', indname=>'STEP_ACTIVE_ID', degree=>4, no_invalidate=>false, force=>true);
exec dbms_stats.gather_index_stats(ownname=>'PROD', indname=>'STEP_ACTIVE_LAST_DT', degree=>4, no_invalidate=>false, force=>true);
exec dbms_stats.gather_index_stats(ownname=>'PROD', indname=>'STEP_ACTIVE_STATE_TXT', degree=>4, no_invalidate=>false, force=>true);
exec dbms_stats.gather_index_stats(ownname=>'PROD', indname=>'STEP_CONTEXT_ID', degree=>4, no_invalidate=>false, force=>true);
exec dbms_stats.gather_index_stats(ownname=>'PROD', indname=>'STEP_LATEST_ID_TYPE', degree=>4, no_invalidate=>false, force=>true);
exec dbms_stats.gather_index_stats(ownname=>'PROD', indname=>'STEP_ACTIVE_OPS', degree=>4, no_invalidate=>false, force=>true);


exec dbms_stats.gather_index_stats(ownname=>'PROD', indname=>'CC_AEDBA_1', degree=>4, no_invalidate=>false, force=>true);


exec dbms_stats.gather_index_stats(ownname=>'PROD', indname=>'CC_AEDBA_2', degree=>4, no_invalidate=>false, force=>true);


15




BLOB_SUPPLIER

exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'USER_ACCOUNT',  degree=>4, cascade=>true);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'USER_ACCOUNT_X_MEMBER_OF',  degree=>4, cascade=>true);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'GROUP_POLICY',  degree=>4, cascade=>true);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'GROUP_POLICY_X_MEMBER_OF',  degree=>4, cascade=>true);








exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'MEMBER_LINK',  degree=>4, cascade=>true);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'UDT_VALUE_LINK',  degree=>4, cascade=>true);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'MEMBERSHIP',  degree=>4, cascade=>true);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'SUBSCRIPTION',  degree=>4, cascade=>true);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'RLTP_TO_SUBSCRB_DEF',  degree=>4, cascade=>true);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'INDIVIDUAL_INFORMATION',  degree=>4, cascade=>true);
exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'INTER_SERV_AUTH',  degree=>6, cascade=>true);




exec dbms_stats.gather_table_stats(ownname=>'PROD_DW', tabname=>'BNFT_PLAN_TEMPLATE_HIST_FACT',  degree=>6, cascade=>true,force=>true);
exec dbms_stats.gather_table_stats(ownname=>'PROD_DW', tabname=>'VALUE_LIST_HISTORY_FACT',  degree=>6, cascade=>true,force=>true);
exec dbms_stats.gather_table_stats(ownname=>'PROD_DW', tabname=>'VALUE_LIST_SLOT',  degree=>6, cascade=>true,force=>true);

exec dbms_stats.gather_table_stats(ownname=>'PROD_DW', tabname=>'ALL_CLAIM_FACT',  degree=>6, cascade=>true,force=>true);


EXECUTE DBMS_STATS.LOCK_TABLE_STATS ('PROD_DW', 'OWNERSHIP_LOG_ENTRY_FACT');
exec dbms_stats.gather_table_stats(ownname=>'PROD_DW', tabname=>'OWNERSHIP_LOG_ENTRY_FACT',  degree=>6, cascade=>true,force=>true);


bnft_plan_template_hist_fact
value_list_history_fact   
value_list_slot



blob_inter_serv_auth 

2. Run extended stats for specific columns.

!! You can use following package instead same thing
###select dbms_stats.create_extended_stats('PROD', 'MEMBERSHIP', '(MBRSHP_ID,CONCEPT_FULFILLED_CD)') from dual;


BEGIN
  DBMS_STATS.gather_table_stats(
    'PROD',
    'OUTSTANDING_PAYABLE',
    method_opt => 'for columns (payable_id,spplr_loc_id)');
END;
/

BEGIN
  DBMS_STATS.gather_table_stats(
    'PROD',
    'CLAIM_PAYABLE',
     degree=>4 ,method_opt => 'for columns (payable_id,tenant_id)');
END;
/


select extension_name, extension from   dba_stat_extensions where  table_name = 'OUTSTANDING_PAYABLE';
select extension_name, extension from   dba_stat_extensions where  table_name = 'CLAIM_PAYABLE';


exec dbms_stats.gather_table_stats(ownname=>'AE_CUSTOM', tabname=>'BOT_IFP_TRIGGER_XREF', degree=>4, no_invalidate=>false); 


exec dbms_stats.gather_table_stats(ownname=>'SC_BASE', tabname=>'NAME_GROUP_LINK', degree=>4, no_invalidate=>false); 


exec dbms_stats.gather_index_stats(ownname=>'PROD', indname=>'SPPLR_X_OTHR_ID_LST_AEDBA_1', degree=>6, no_invalidate=>false, force=>true);

exec dbms_stats.gather_table_stats(ownname=>'PROD', tabname=>'PAYABLE',  degree=>6, cascade=>true,force=>true);


exec dbms_stats.gather_index_stats(ownname=>'PROD', indname=>'FK_CO_CLM_CD_RY_NON_PA_TYPE', degree=>6, no_invalidate=>false, force=>true);
exec dbms_stats.gather_index_stats(ownname=>'PROD', indname=>'CLAIM_SEARCH_IDX3', degree=>6, no_invalidate=>false, force=>true);
exec dbms_stats.gather_index_stats(ownname=>'PROD', indname=>'CLAIM_SEARCH_IDX1', degree=>6, no_invalidate=>false, force=>true);
exec dbms_stats.gather_index_stats(ownname=>'PROD', indname=>'CFLS_INDX', degree=>6, no_invalidate=>false, force=>true);

exec dbms_stats.gather_index_stats(ownname=>'PROD', indname=>'FK_TRANS_D_SERV_BNFT_K_BNFT_K', degree=>6, no_invalidate=>false, force=>true);
exec dbms_stats.gather_index_stats(ownname=>'PROD', indname=>'FK_PAYEE_OTHR_INS_CO', degree=>6, no_invalidate=>false, force=>true);
exec dbms_stats.gather_index_stats(ownname=>'PROD', indname=>'MEMBERSHIP_AEDBA_2', degree=>8, no_invalidate=>false, force=>true);


************************* LOCKED STATS OR NOT ***********************

SELECT OWNER, TABLE_NAME, STATTYPE_LOCKED FROM DBA_TAB_STATISTICS 
WHERE STATTYPE_LOCKED IS NOT NULL and table_name = 'OWNERSHIP_LOG_ENTRY_FACT' ;


SELECT OWNER, TABLE_NAME, STATTYPE_LOCKED FROM DBA_TAB_STATISTICS 
WHERE STATTYPE_LOCKED IS NOT NULL AND OWNER = 'PROD' ORDER BY 2;

******************************************************************


*********** Stale stats example ******************************

Timing issue with stats as the stats are currently stale.

--Row Count
select count(*) from PROD.BACK_FEED_PAYMENT_STATUS;
251,392

--Rows Touched after Stats were gathered
select count(*) from PROD.BACK_FEED_PAYMENT_STATUS where last_tx_dt > to_timestamp('2024-10-09 02:10:14','YYYY-MM-DD HH24:MI:SS');
121,044

--Stats Information
select num_rows,last_analyzed,stale_stats from dba_tab_statistics where table_name = 'BACK_FEED_PAYMENT_STATUS';

NUM_ROWS      LAST_ANALYZED             STALE_STATS
210,964              10/9/2024 2:10:14 AM YES


I assume a batch process is in play here as I see the last_tx_user_txt is eie_service.  Looks like the process finished much later this morning than yesterday.
Can a gather stats be added to the end of this process or is this a vendor delivered process?

