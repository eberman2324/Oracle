Peoplesoft DPP 12c
==================

1) Create the Wallet directory for each database on server




   mkdir -p $ORACLE_BASE/admin/DPDEVUG/wallet 

   chmod 700 $ORACLE_BASE/admin/DPDEVUG/wallet


   mkdir -p $ORACLE_BASE/admin/DPDEV92/wallet 

   chmod 700 $ORACLE_BASE/admin/DPDEV92/wallet


2) Backup the sqlnet.ora file

   cd $ORACLE_HOME/network/admin

   cp -p sqlnet.ora sqlnet.ora_b4_encryption


3) Add TDE setup to the sqlnet.ora file
 


SQLNET.ENCRYPTION_TYPES_SERVER= (AES128)
SQLNET.ENCRYPTION_SERVER = requested


3) Backup, OEM Blackout 



  

   cd $BKPSCR
   savebkp.ksh DPDEVUG b4encryption

   DPDEVUG backup saved as DPDEVUG_sbk_20161005_05:01:10_b4encryption.rman

   

   cd $BKPSCR
   savebkp.ksh DPDEV92 b4encryption

   DPDEV92 backup saved as DPDEV92_sbk_20161007_02:45:10_b4encryption.rman

   Create OEM Blackout



4) Create the 12c Wallet

   sqlplus / as sysdba

   ADMINISTER KEY MANAGEMENT CREATE KEYSTORE '/orahome/u01/app/oracle/admin/DPDEV92/wallet/' IDENTIFIED BY "F1shF00d";
   ADMINISTER KEY MANAGEMENT CREATE AUTO_LOGIN KEYSTORE FROM KEYSTORE '/orahome/u01/app/oracle/admin/DPDEV92/wallet/' IDENTIFIED BY "F1shF00d";

   -- Open 12c Wallet
   ADMINISTER KEY MANAGEMENT SET KEYSTORE OPEN IDENTIFIED BY "F1shF00d";

   -- Create 12c master key
   ADMINISTER KEY MANAGEMENT SET KEY IDENTIFIED BY "F1shF00d" WITH BACKUP;
   ADMINISTER KEY MANAGEMENT SET KEY USING TAG 'peoplesoft_DPDEV92' IDENTIFIED BY "F1shF00d" WITH BACKUP USING 'peoplesoft_backup_DPDEV92';



5) turn on autoextend for all tablespaces 




cd /u01/app/oracle/aetna/admin/DPDEV92/encryption



sqlplus / as sysdba

       sql =>   @ext_alter_datafiles_autoextend.sql    (1 minute)
                    !view alter_datafiles_autoextend.sql  ?  review script to be run

•	Turn on autoextend

       sql => @alter_datafiles_autoextend.sql   (1 minute)
      sql =>   exit
     view alter_datafiles_autoextend.out  ?  review script output









   --encrypt table columns

##Toms drop index scripts

$HOME/tls/encrypt


cd /u01/app/oracle/aetna/admin/DPDEV92/encryption

@encryptTblCol.sql


ALTER TABLE SYSADM.PS_AUDIT_KNS_DMOST MODIFY (SSN encrypt no salt);
ALTER TABLE SYSADM.PS_AUDIT_OVPD_CALC MODIFY (SSN encrypt no salt);
ALTER TABLE SYSADM.PS_AUDIT_OVPD_CLAM MODIFY (SSN encrypt no salt);
ALTER TABLE SYSADM.PS_AUDIT_OVPD_NOTS MODIFY (SSN encrypt no salt);
ALTER TABLE SYSADM.PS_AUDIT_REPAY_RCD MODIFY (SSN encrypt no salt);
ALTER TABLE SYSADM.PS_KNS_ALT_ADDR MODIFY (SSN encrypt no salt);
ALTER TABLE SYSADM.PS_KNS_DED_HIST MODIFY (SSN encrypt no salt);
ALTER TABLE SYSADM.PS_KNS_DED_STAGE MODIFY (SSN encrypt no salt);
ALTER TABLE SYSADM.PS_KNS_DEMO_HIST MODIFY (SSN encrypt no salt);
ALTER TABLE SYSADM.PS_KNS_DEMO_STAGE MODIFY (SSN encrypt no salt);
ALTER TABLE SYSADM.PS_KNS_DIRDEP_WKVW MODIFY (SSN encrypt no salt);
ALTER TABLE SYSADM.PS_KNS_EMPLID MODIFY (SSN encrypt no salt);
ALTER TABLE SYSADM.PS_KNS_KNI027_TBL MODIFY (SSN encrypt no salt);
ALTER TABLE SYSADM.PS_KNS_KNP013_TEMP MODIFY (SSN encrypt no salt);
ALTER TABLE SYSADM.PS_KNS_KNR030_TEMP MODIFY (SSN encrypt no salt);
ALTER TABLE SYSADM.PS_KNS_KNR031_TMP MODIFY (SSN encrypt no salt);
ALTER TABLE SYSADM.PS_KNS_KNR036_CSV MODIFY (SSN encrypt no salt);
ALTER TABLE SYSADM.PS_KNS_OVPD_BAL MODIFY (SSN encrypt no salt);
ALTER TABLE SYSADM.PS_KNS_OVPD_CALC MODIFY (SSN encrypt no salt);
ALTER TABLE SYSADM.PS_KNS_OVPD_CLAIMS MODIFY (SSN encrypt no salt);
ALTER TABLE SYSADM.PS_KNS_OVPD_CLM_CN MODIFY (SSN encrypt no salt);
ALTER TABLE SYSADM.PS_KNS_OVPD_DOCS MODIFY (SSN encrypt no salt);
ALTER TABLE SYSADM.PS_KNS_OVPD_NOTES MODIFY (SSN encrypt no salt);
ALTER TABLE SYSADM.PS_KNS_REPAY_RECD MODIFY (SSN encrypt no salt);
ALTER TABLE SYSADM.PS_KNS_REVRS_RQST MODIFY (SSN encrypt no salt);
ALTER TABLE SYSADM.PS_KNS_RUNCNTL_PAY MODIFY (SSN encrypt no salt);
ALTER TABLE SYSADM.PS_KNS_SPC_HNDL MODIFY (SSN encrypt no salt);
ALTER TABLE SYSADM.PS_KNS_SPS_CLMT MODIFY (SSN encrypt no salt);
ALTER TABLE SYSADM.PS_KNS_SSN_AUDIT MODIFY (SSN encrypt no salt);
ALTER TABLE SYSADM.PS_KNS_TXFM_PRTSEL MODIFY (SSN encrypt no salt);
ALTER TABLE SYSADM.PS_KNS_VW_DEDUCTNS MODIFY (SSN encrypt no salt);
ALTER TABLE SYSADM.PS_KNS_VW_EARNINGS MODIFY (SSN encrypt no salt);
ALTER TABLE SYSADM.PS_KNS_VW_PAYMENTS MODIFY (SSN encrypt no salt);
ALTER TABLE SYSADM.PS_KNS_VW_TAXES MODIFY (SSN encrypt no salt);
ALTER TABLE SYSADM.PS_PAY_CHECK MODIFY (SSN encrypt no salt);
ALTER TABLE SYSADM.PS_YE_DATA MODIFY (SSN encrypt no salt);
ALTER TABLE SYSADM.PS_AUDIT_KNS_TESTG MODIFY (KNS_PARTC_ID encrypt no salt);
ALTER TABLE SYSADM.PS_KNS_CLAIM_TMP MODIFY (KNS_PARTC_ID encrypt no salt);
ALTER TABLE SYSADM.PS_KNS_DED_HIST MODIFY (KNS_PARTC_ID encrypt no salt);
ALTER TABLE SYSADM.PS_KNS_DED_STAGE MODIFY (KNS_PARTC_ID encrypt no salt);
ALTER TABLE SYSADM.PS_KNS_DEMO_ERRLOG MODIFY (KNS_PARTC_ID encrypt no salt);
ALTER TABLE SYSADM.PS_KNS_DEMO_HIST MODIFY (KNS_PARTC_ID encrypt no salt);
ALTER TABLE SYSADM.PS_KNS_DEMO_STAGE MODIFY (KNS_PARTC_ID encrypt no salt);
ALTER TABLE SYSADM.PS_KNS_DEMO_STATS MODIFY (KNS_PARTC_ID encrypt no salt);
ALTER TABLE SYSADM.PS_KNS_EMPLID MODIFY (KNS_PARTC_ID encrypt no salt);
ALTER TABLE SYSADM.PS_KNS_ERNCD_STAGE MODIFY (KNS_PARTC_ID encrypt no salt);
ALTER TABLE SYSADM.PS_KNS_HIST_CHILD MODIFY (KNS_PARTC_ID encrypt no salt);
ALTER TABLE SYSADM.PS_KNS_HIST_TRANS MODIFY (KNS_PARTC_ID encrypt no salt);
ALTER TABLE SYSADM.PS_KNS_KNI001_RPT MODIFY (KNS_PARTC_ID encrypt no salt);
ALTER TABLE SYSADM.PS_KNS_PAY_CHECK MODIFY (KNS_PARTC_ID encrypt no salt);
ALTER TABLE SYSADM.PS_KNS_TE_ALT_PAY MODIFY (KNS_PARTC_ID encrypt no salt);
ALTER TABLE SYSADM.PS_KNS_TE_ERR_TMP MODIFY (KNS_PARTC_ID encrypt no salt);
ALTER TABLE SYSADM.PS_KNS_TE_HISTORY MODIFY (KNS_PARTC_ID encrypt no salt);
ALTER TABLE SYSADM.PS_KNS_TE_STAGING MODIFY (KNS_PARTC_ID encrypt no salt);
ALTER TABLE SYSADM.PS_KNS_REPAY_STG MODIFY (NATIONAL_ID encrypt no salt);
ALTER TABLE SYSADM.PS_KNS_TMP_TAX MODIFY (NATIONAL_ID encrypt no salt);
ALTER TABLE SYSADM.PS_KNS_TMP_TAX_LOC MODIFY (NATIONAL_ID encrypt no salt);
ALTER TABLE SYSADM.PS_KNS_TMP_TAX_STA MODIFY (NATIONAL_ID encrypt no salt);
ALTER TABLE SYSADM.PS_PERS_NID MODIFY (NATIONAL_ID encrypt no salt);
ALTER TABLE SYSADM.PS_SJT_PERSON MODIFY (NATIONAL_ID encrypt no salt);
ALTER TABLE SYSADM.PS_YE_W2CP_DATA MODIFY (W2C_SSN encrypt no salt);
ALTER TABLE SYSADM.PS_YE_W2C_DATA MODIFY (W2C_SSN encrypt no salt);
ALTER TABLE SYSADM.PS_YE_W2CP_AMOUNTS MODIFY (PRV_SSN encrypt no salt);
ALTER TABLE SYSADM.PS_YE_W2CP_DATA MODIFY (PRV_SSN encrypt no salt);
ALTER TABLE SYSADM.PS_YE_W2C_AMOUNTS MODIFY (PRV_SSN encrypt no salt);
ALTER TABLE SYSADM.PS_YE_W2C_DATA MODIFY (PRV_SSN encrypt no salt);
ALTER TABLE SYSADM.PS_YE_W2CP_DATA MODIFY (PRV_SPOUSE_SSN encrypt no salt);
ALTER TABLE SYSADM.PS_YE_DATA MODIFY (SPOUSE_SSN encrypt no salt);
ALTER TABLE SYSADM.PS_YE_W2CP_DATA MODIFY (SPOUSE_SSN encrypt no salt);


--Move tables


cd /u01/app/oracle/aetna/admin/DPDEV92/encryption

@moveTbl.sql


ALTER TABLE SYSADM.PS_AUDIT_KNS_DMOST MOVE TABLESPACE KNSAPP;
ALTER TABLE SYSADM.PS_AUDIT_KNS_TESTG MOVE TABLESPACE KNSAPP;
ALTER TABLE SYSADM.PS_AUDIT_OVPD_CALC MOVE TABLESPACE PYLARGE;
ALTER TABLE SYSADM.PS_AUDIT_OVPD_CLAM MOVE TABLESPACE PYLARGE;
ALTER TABLE SYSADM.PS_AUDIT_OVPD_NOTS MOVE TABLESPACE PYLARGE;
ALTER TABLE SYSADM.PS_AUDIT_REPAY_RCD MOVE TABLESPACE PYLARGE;
ALTER TABLE SYSADM.PS_KNS_ALT_ADDR MOVE TABLESPACE PYLARGE;
ALTER TABLE SYSADM.PS_KNS_CLAIM_TMP MOVE TABLESPACE PYLARGE;
ALTER TABLE SYSADM.PS_KNS_DED_HIST MOVE TABLESPACE PYLARGE;
ALTER TABLE SYSADM.PS_KNS_DED_STAGE MOVE TABLESPACE PYLARGE;
ALTER TABLE SYSADM.PS_KNS_DEMO_ERRLOG MOVE TABLESPACE HRLARGE;
ALTER TABLE SYSADM.PS_KNS_DEMO_HIST MOVE TABLESPACE KNSAPP;
ALTER TABLE SYSADM.PS_KNS_DEMO_STAGE MOVE TABLESPACE KNSAPP;
ALTER TABLE SYSADM.PS_KNS_DEMO_STATS MOVE TABLESPACE PYLARGE;
ALTER TABLE SYSADM.PS_KNS_DIRDEP_WKVW MOVE TABLESPACE KNSAPP;
ALTER TABLE SYSADM.PS_KNS_EMPLID MOVE TABLESPACE HRLARGE;
ALTER TABLE SYSADM.PS_KNS_ERNCD_STAGE MOVE TABLESPACE PYLARGE;
ALTER TABLE SYSADM.PS_KNS_HIST_CHILD MOVE TABLESPACE PYLARGE;
ALTER TABLE SYSADM.PS_KNS_HIST_TRANS MOVE TABLESPACE PYLARGE;
ALTER TABLE SYSADM.PS_KNS_KNI001_RPT MOVE TABLESPACE HRLARGE;
ALTER TABLE SYSADM.PS_KNS_KNI027_TBL MOVE TABLESPACE PYLARGE;
ALTER TABLE SYSADM.PS_KNS_KNP013_TEMP MOVE TABLESPACE KNSAPP;
ALTER TABLE SYSADM.PS_KNS_KNR030_TEMP MOVE TABLESPACE HRLARGE;
ALTER TABLE SYSADM.PS_KNS_KNR031_TMP MOVE TABLESPACE KNSAPP;
ALTER TABLE SYSADM.PS_KNS_KNR036_CSV MOVE TABLESPACE KNSAPP;
ALTER TABLE SYSADM.PS_KNS_OVPD_BAL MOVE TABLESPACE HRLARGE;
ALTER TABLE SYSADM.PS_KNS_OVPD_CALC MOVE TABLESPACE KNSAPP;
ALTER TABLE SYSADM.PS_KNS_OVPD_CLAIMS MOVE TABLESPACE KNSAPP;
ALTER TABLE SYSADM.PS_KNS_OVPD_CLM_CN MOVE TABLESPACE KNSAPP;
ALTER TABLE SYSADM.PS_KNS_OVPD_DOCS MOVE TABLESPACE KNSAPP;
ALTER TABLE SYSADM.PS_KNS_OVPD_NOTES MOVE TABLESPACE KNSAPP;
ALTER TABLE SYSADM.PS_KNS_PAY_CHECK MOVE TABLESPACE HRLARGE;
ALTER TABLE SYSADM.PS_KNS_REPAY_RECD MOVE TABLESPACE KNSAPP;
ALTER TABLE SYSADM.PS_KNS_REPAY_STG MOVE TABLESPACE KNSAPP;
ALTER TABLE SYSADM.PS_KNS_REVRS_RQST MOVE TABLESPACE PYLARGE;
ALTER TABLE SYSADM.PS_KNS_RUNCNTL_PAY MOVE TABLESPACE PYAPP;
ALTER TABLE SYSADM.PS_KNS_SPC_HNDL MOVE TABLESPACE KNSAPP;
ALTER TABLE SYSADM.PS_KNS_SPS_CLMT MOVE TABLESPACE PYLARGE;
ALTER TABLE SYSADM.PS_KNS_SSN_AUDIT MOVE TABLESPACE KNSAPP;
ALTER TABLE SYSADM.PS_KNS_TE_ALT_PAY MOVE TABLESPACE PYAPP;
ALTER TABLE SYSADM.PS_KNS_TE_ERR_TMP MOVE TABLESPACE HRLARGE;
ALTER TABLE SYSADM.PS_KNS_TE_HISTORY MOVE TABLESPACE HRLARGE;
ALTER TABLE SYSADM.PS_KNS_TMP_TAX MOVE TABLESPACE KNSAPP;
ALTER TABLE SYSADM.PS_KNS_TMP_TAX_LOC MOVE TABLESPACE KNSAPP;
ALTER TABLE SYSADM.PS_KNS_TMP_TAX_STA MOVE TABLESPACE KNSAPP;
ALTER TABLE SYSADM.PS_KNS_TXFM_PRTSEL MOVE TABLESPACE KNSAPP;
ALTER TABLE SYSADM.PS_KNS_VW_DEDUCTNS MOVE TABLESPACE KNSAPP;
ALTER TABLE SYSADM.PS_KNS_VW_EARNINGS MOVE TABLESPACE KNSAPP;
ALTER TABLE SYSADM.PS_KNS_VW_PAYMENTS MOVE TABLESPACE KNSAPP;
ALTER TABLE SYSADM.PS_KNS_VW_TAXES MOVE TABLESPACE KNSAPP;
ALTER TABLE SYSADM.PS_PAY_CHECK MOVE TABLESPACE PYLARGE;
ALTER TABLE SYSADM.PS_PERS_NID MOVE TABLESPACE HRLARGE;
ALTER TABLE SYSADM.PS_SJT_PERSON MOVE TABLESPACE HRLARGE;
ALTER TABLE SYSADM.PS_YE_DATA MOVE TABLESPACE PYLARGE;
ALTER TABLE SYSADM.PS_YE_W2CP_AMOUNTS MOVE TABLESPACE PYLARGE;
ALTER TABLE SYSADM.PS_YE_W2CP_DATA MOVE TABLESPACE PYLARGE;
ALTER TABLE SYSADM.PS_YE_W2C_AMOUNTS MOVE TABLESPACE PYLARGE;
ALTER TABLE SYSADM.PS_YE_W2C_DATA MOVE TABLESPACE PYLARGE;


ERROR at line 1:
ORA-01652: unable to extend temp segment by 1024 in tablespace HRLARGE

--Rebuild Indexes (LOB indexes excluded)

cd /u01/app/oracle/aetna/admin/DPDEV92/encryption

@reBuildInd.sql



ALTER INDEX SYSADM.PS_AUDIT_KNS_DMOST rebuild;
ALTER INDEX SYSADM.PS_AUDIT_KNS_TESTG rebuild;
ALTER INDEX SYSADM.PS_AUDIT_OVPD_CALC rebuild;
ALTER INDEX SYSADM.PS_AUDIT_OVPD_CLAM rebuild;
ALTER INDEX SYSADM.PS_AUDIT_OVPD_NOTS rebuild;
ALTER INDEX SYSADM.PS_AUDIT_REPAY_RCD rebuild;
ALTER INDEX SYSADM.PS_KNS_ALT_ADDR rebuild;
ALTER INDEX SYSADM.PS_KNS_CLAIM_TMP rebuild;
ALTER INDEX SYSADM.PSAKNS_DED_HIST rebuild;
ALTER INDEX SYSADM.PSBKNS_DED_HIST rebuild;
ALTER INDEX SYSADM.PS_KNS_DED_HIST rebuild;
ALTER INDEX SYSADM.PSAKNS_DED_STAGE rebuild;
ALTER INDEX SYSADM.PSBKNS_DED_STAGE rebuild;
ALTER INDEX SYSADM.PS_KNS_DED_STAGE rebuild;
ALTER INDEX SYSADM.PS_KNS_DEMO_ERRLOG rebuild;
ALTER INDEX SYSADM.PSAKNS_DEMO_HIST rebuild;
ALTER INDEX SYSADM.PSBKNS_DEMO_HIST rebuild;
ALTER INDEX SYSADM.PS_KNS_DEMO_HIST rebuild;
ALTER INDEX SYSADM.PSAKNS_DEMO_STAGE rebuild;
ALTER INDEX SYSADM.PSBKNS_DEMO_STAGE rebuild;
ALTER INDEX SYSADM.PS_KNS_DEMO_STAGE rebuild;
ALTER INDEX SYSADM.PS_KNS_DEMO_STATS rebuild;
ALTER INDEX SYSADM.PSAKNS_DIRDEP_WKVW rebuild;
ALTER INDEX SYSADM.PS_KNS_DIRDEP_WKVW rebuild;
ALTER INDEX SYSADM.PSAKNS_EMPLID rebuild;
ALTER INDEX SYSADM.PSBKNS_EMPLID rebuild;
ALTER INDEX SYSADM.PSCKNS_EMPLID rebuild;
ALTER INDEX SYSADM.PS_KNS_EMPLID rebuild;
ALTER INDEX SYSADM.PS_KNS_ERNCD_STAGE rebuild;
ALTER INDEX SYSADM.PS_KNS_HIST_CHILD rebuild;
ALTER INDEX SYSADM.PS_KNS_HIST_TRANS rebuild;
ALTER INDEX SYSADM.PS_KNS_KNI001_RPT rebuild;
ALTER INDEX SYSADM.PS_KNS_KNI027_TBL rebuild;
ALTER INDEX SYSADM.PS_KNS_KNP013_TEMP rebuild;
ALTER INDEX SYSADM.PSAKNS_KNR030_TEMP rebuild;
ALTER INDEX SYSADM.PS_KNS_KNR031_TMP rebuild;
ALTER INDEX SYSADM.PS_KNS_KNR036_CSV rebuild;
ALTER INDEX SYSADM.PSAKNS_OVPD_BAL rebuild;
ALTER INDEX SYSADM.PS_KNS_OVPD_BAL rebuild;
ALTER INDEX SYSADM.PS_KNS_OVPD_CALC rebuild;
ALTER INDEX SYSADM.PS_KNS_OVPD_CLAIMS rebuild;
ALTER INDEX SYSADM.PS_KNS_OVPD_CLM_CN rebuild;
ALTER INDEX SYSADM.PS_KNS_OVPD_DOCS rebuild;
ALTER INDEX SYSADM.PS_KNS_OVPD_NOTES rebuild;
ALTER INDEX SYSADM.PSAKNS_PAY_CHECK rebuild;
ALTER INDEX SYSADM.PSBKNS_PAY_CHECK rebuild;
ALTER INDEX SYSADM.PSCKNS_PAY_CHECK rebuild;
ALTER INDEX SYSADM.PSDKNS_PAY_CHECK rebuild;
ALTER INDEX SYSADM.PSEKNS_PAY_CHECK rebuild;
ALTER INDEX SYSADM.PSFKNS_PAY_CHECK rebuild;
ALTER INDEX SYSADM.PSGKNS_PAY_CHECK rebuild;
ALTER INDEX SYSADM.PS_KNS_PAY_CHECK rebuild;
ALTER INDEX SYSADM.PS_KNS_REPAY_RECD rebuild;
ALTER INDEX SYSADM.PS_KNS_REPAY_STG rebuild;
ALTER INDEX SYSADM.PS_KNS_REVRS_RQST rebuild;
ALTER INDEX SYSADM.PS_KNS_RUNCNTL_PAY rebuild;
ALTER INDEX SYSADM.PSAKNS_SPC_HNDL rebuild;
ALTER INDEX SYSADM.PS_KNS_SPC_HNDL rebuild;
ALTER INDEX SYSADM.PS_KNS_SPS_CLMT rebuild;
ALTER INDEX SYSADM.PS0KNS_SSN_AUDIT rebuild;
ALTER INDEX SYSADM.PS1KNS_SSN_AUDIT rebuild;
ALTER INDEX SYSADM.PS2KNS_SSN_AUDIT rebuild;
ALTER INDEX SYSADM.PS3KNS_SSN_AUDIT rebuild;
ALTER INDEX SYSADM.PS_KNS_SSN_AUDIT rebuild;
ALTER INDEX SYSADM.PS0KNS_TE_ALT_PAY rebuild;
ALTER INDEX SYSADM.PS_KNS_TE_ALT_PAY rebuild;
ALTER INDEX SYSADM.PS_KNS_TE_ERR_TMP rebuild;
ALTER INDEX SYSADM.PSAKNS_TE_HISTORY rebuild;
ALTER INDEX SYSADM.PS_KNS_TE_HISTORY rebuild;
ALTER INDEX SYSADM.PS0KNS_TMP_TAX rebuild;
ALTER INDEX SYSADM.PS_KNS_TMP_TAX rebuild;
ALTER INDEX SYSADM.PS_KNS_TMP_TAX_LOC rebuild;
ALTER INDEX SYSADM.PS_KNS_TMP_TAX_STA rebuild;
ALTER INDEX SYSADM.PSAKNS_TXFM_PRTSEL rebuild;
ALTER INDEX SYSADM.PS_KNS_TXFM_PRTSEL rebuild;
ALTER INDEX SYSADM.PS_KNS_VW_DEDUCTNS rebuild;
ALTER INDEX SYSADM.PS_KNS_VW_EARNINGS rebuild;
ALTER INDEX SYSADM.PSAKNS_VW_PAYMENTS rebuild;
ALTER INDEX SYSADM.PSAKNS_VW_PAYMENTS_TC rebuild;
ALTER INDEX SYSADM.PSBKNS_VW_PAYMENTS rebuild;
ALTER INDEX SYSADM.PS_KNS_VW_PAYMENTS rebuild;
ALTER INDEX SYSADM.PS_KNS_VW_TAXES rebuild;
ALTER INDEX SYSADM.PS0PAY_CHECK rebuild;
ALTER INDEX SYSADM.PS1PAY_CHECK rebuild;
ALTER INDEX SYSADM.PS2PAY_CHECK rebuild;
ALTER INDEX SYSADM.PSAPAY_CHECK rebuild;
ALTER INDEX SYSADM.PSEPAY_CHECK rebuild;
ALTER INDEX SYSADM.PSFPAY_CHECK rebuild;
ALTER INDEX SYSADM.PSGPAY_CHECK rebuild;
ALTER INDEX SYSADM.PSHPAY_CHECK rebuild;
ALTER INDEX SYSADM.PS_PAY_CHECK rebuild;
ALTER INDEX SYSADM.PSAPERS_NID rebuild;
ALTER INDEX SYSADM.PS_PERS_NID rebuild;
ALTER INDEX SYSADM.PSASJT_PERSON rebuild;
ALTER INDEX SYSADM.PS_SJT_PERSON rebuild;
ALTER INDEX SYSADM.PS_YE_DATA rebuild;
ALTER INDEX SYSADM.PS_YE_W2CP_AMOUNTS rebuild;
ALTER INDEX SYSADM.PS0YE_W2CP_DATA rebuild;
ALTER INDEX SYSADM.PS1YE_W2CP_DATA rebuild;
ALTER INDEX SYSADM.PS_YE_W2CP_DATA rebuild;
ALTER INDEX SYSADM.PS_YE_W2C_AMOUNTS rebuild;
ALTER INDEX SYSADM.PS0YE_W2C_DATA rebuild;
ALTER INDEX SYSADM.PS_YE_W2C_DATA rebuild;

SQL> ALTER INDEX SYSADM.PSAKNS_VW_PAYMENTS_TC rebuild
*
ERROR at line 1:
ORA-01418: specified index does not exist


SQL> ALTER INDEX SYSADM.PSBKNS_VW_PAYMENTS rebuild
*
ERROR at line 1:
ORA-01418: specified index does not exist




## Quick test/check

select KNS_PARTC_ID from SYSADM.PS_KNS_ERNCD_STAGE

## Make sure it shows correct path
select * from V$ENCRYPTION_WALLET;
select * from DBA_ENCRYPTED_COLUMNS;


extract DDL from SYSADM.PS_YE_W2CP_DATA to make sure encryption there


run => sqlplus / as sysdba

      sql => @alter_datafiles_autoextend_off.sql   (1 minute)

      sql => !view alter_datafiles_autoextend_off.out  ?  review script to be run


      exit






5) Use below as a reference for setting up export backup job

   Doc ID 2085607.1

   Still needs to be done.


ADMINISTER KEY MANAGEMENT EXPORT KEYS WITH SECRET "F1shF00d" TO '/tmp/export_DPDEV92.exp' IDENTIFIED BY F1shF00d; 

ERROR at line 1:
ORA-46642: key export destination file already exists


${HOME}/aetna/scripts/heartbeat.ksh DPDEV92 > /dev/null


--Test import


ADMINISTER KEY MANAGEMENT IMPORT KEYS WITH SECRET "F1shF00d" FROM '/tmp/export_DPDEV92.exp' IDENTIFIED BY F1shF00d WITH BACKUP;
  
  
  
Doc ID 2156693.1

ADMINISTER KEY MANAGEMENT IMPORT KEYS WITH SECRET fails with:

ORA-46655: no valid keys in the file from which keys are to be imported

ERROR at line 1:
ORA-46655: no valid keys in the file from which keys are to be imported

  

https://docs.oracle.com/database/121/SQLRF/statements_1003.htm#SQLRF55976


[?10/?05/?2016 11:17 AM] Schloendorn, Thomas: 
ok
I would two things in reagrds to the Walle
t
1) Get the backup copy going as illustrated in the doc
[?10/?05/?2016 11:19 AM] Schloendorn, Thomas: 
2) set up a cron jon to backup the wallet directory regularly
dsmc


@?/rdbms/admin/utlrp.sql

select count(*)
from dba_objects
where status = 'INVALID';

Thu Oct 06 02:17:55 2016 NI cryptographic checksum mismatch error: 12599.
Thu Oct 06 02:17:55 2016   Tns error struct:
Doc ID 1927120.1



************Steps to Migrate wallet to different dir *********

 mkdir -p $ORACLE_BASE/admin/DPDEVUG/wallet 

    chmod 700 $ORACLE_BASE/admin/DPDEVUG/wallet


   ADMINISTER KEY MANAGEMENT SET KEYSTORE CLOSE IDENTIFIED BY "F1shF00d";

cwallet.sso
ewallet.p12
ewallet_2016100515442212.p12
ewallet_2016100515443546_peoplesoft_backup.p12

cd /orahome/u01/app/oracle/encryption_wallet/

cp -p cwallet.sso $ORACLE_BASE/admin/DPDEVUG/wallet/cwallet.sso
cp -p ewallet.p12 $ORACLE_BASE/admin/DPDEVUG/wallet/ewallet.p12
cp -p ewallet_2016100515442212.p12 $ORACLE_BASE/admin/DPDEVUG/wallet/ewallet_2016100515442212.p12
cp -p ewallet_2016100515443546_peoplesoft_backup.p12 $ORACLE_BASE/admin/DPDEVUG/wallet/ewallet_2016100515443546_peoplesoft_backup.p12


remove following from sqlnet.ora

ENCRYPTION_WALLET_LOCATION =
  (SOURCE =
    (METHOD = FILE)
    (METHOD_DATA =
      (DIRECTORY = /orahome/u01/app/oracle/encryption_wallet/)
    )
  )


ADMINISTER KEY MANAGEMENT SET KEYSTORE OPEN IDENTIFIED BY "F1shF00d";


select KNS_PARTC_ID from SYSADM.PS_KNS_ERNCD_STAGE

## Make sure it shows correct path
select * from V$ENCRYPTION_WALLET;
select * from DBA_ENCRYPTED_COLUMNS;




*****************DPPQA***********************



. ~/.profile

DPUAT92


Move scripts from dppdev over to dppqa

login to dppdev

scp -rp /u01/app/oracle/aetna/admin/DPDEV92/encryption dppqa:/u01/app/oracle/aetna/admin/DPUAT92/encryption 


scp -rp /u01/app/oracle/tls/encrypt dppqa:/u01/app/oracle/tls/encrypt




1) Create the Wallet directory for each database on server



   mkdir -p $ORACLE_BASE/admin/DPUAT92/wallet 

   chmod 700 $ORACLE_BASE/admin/DPUAT92/wallet




2) Backup the sqlnet.ora file

   cd $ORACLE_HOME/network/admin

   cp -p sqlnet.ora sqlnet.ora_b4_encryption


3) Add TDE setup to the sqlnet.ora file
 


SQLNET.ENCRYPTION_TYPES_SERVER= (AES128)
SQLNET.ENCRYPTION_SERVER = requested


3) Backup, OEM Blackout 



  Eo5%IQIH

   cd $BKPSCR
   savebkp.ksh DPUAT92 b4encryption

   DPUAT92 backup saved as DPUAT92_sbk_20161016_23:55:02_b4encryption.rman

   

   Create OEM Blackout



4) Create the 12c Wallet

   sqlplus / as sysdba

   ADMINISTER KEY MANAGEMENT CREATE KEYSTORE '/orahome/u01/app/oracle/admin/DPUAT92/wallet/' IDENTIFIED BY "F1shF00d";
   ADMINISTER KEY MANAGEMENT CREATE AUTO_LOGIN KEYSTORE FROM KEYSTORE '/orahome/u01/app/oracle/admin/DPUAT92/wallet/' IDENTIFIED BY "F1shF00d";

   -- Open 12c Wallet
   ADMINISTER KEY MANAGEMENT SET KEYSTORE OPEN IDENTIFIED BY "F1shF00d";

   -- Create 12c master key
   ADMINISTER KEY MANAGEMENT SET KEY IDENTIFIED BY "F1shF00d" WITH BACKUP;
   ADMINISTER KEY MANAGEMENT SET KEY USING TAG 'peoplesoft_DPUAT92' IDENTIFIED BY "F1shF00d" WITH BACKUP USING 'peoplesoft_backup_DPUAT92';


5) turn on autoextend for all tablespaces 








cd /u01/app/oracle/aetna/admin/DPUAT92/encryption 



sqlplus / as sysdba

       sql =>   @ext_alter_datafiles_autoextend.sql    (1 minute)
                    !view alter_datafiles_autoextend.sql  ?  review script to be run

•	Turn on autoextend

       sql => @alter_datafiles_autoextend.sql   (1 minute)
      sql =>   exit
     view alter_datafiles_autoextend.out  ?  review script output









   --encrypt table columns

##Toms drop index scripts

cd $HOME/tls/encrypt

sqlplus / as sysdba

@ext_drop_indexes.sql DPUAT92

@ext_create_indexes.sql DPUAT92

@ext_altix_logging_noparallel.sql DPUAT92
exit

sqlplus / as sysdba

@drop_indexes_DPUAT92.sql

exit

sqlplus / as sysdba




@encrypt_table_columns.sql



######cd /u01/app/oracle/aetna/admin/DPUAT92/encryption

#######@encryptTblCol.sql




--Move tables


####cd /u01/app/oracle/aetna/admin/DPUAT92/encryption

#####@moveTbl.sql


cd $HOME/tls/encrypt


sqlplus / as sysdba

@move_encrypted_tables.sql



--Rebuild Indexes (LOB indexes excluded)

###cd /u01/app/oracle/aetna/admin/DPUAT92/encryption

####@reBuildInd.sql



cd $HOME/tls/encrypt


sqlplus / as sysdba



@create_indexes_DPUAT92.sql


@ext_altix_logging_noparallel.sql DPUAT92

@altix_logging_noparallel_DPUAT92.sql

exit




## Quick test/check. You can use DBArtisan for that.

select KNS_PARTC_ID from SYSADM.PS_KNS_ERNCD_STAGE

## Make sure it shows correct path
select * from V$ENCRYPTION_WALLET;
select * from DBA_ENCRYPTED_COLUMNS;


extract DDL from SYSADM.PS_YE_W2CP_DATA to make sure encryption there


cd /u01/app/oracle/aetna/admin/DPUAT92/encryption


run => sqlplus / as sysdba

      sql => @alter_datafiles_autoextend_off.sql   (1 minute)

      sql => !view alter_datafiles_autoextend_off.out  ?  review script to be run


      exit






5) Run Key backup

   Doc ID 2085607.1




ADMINISTER KEY MANAGEMENT EXPORT KEYS WITH SECRET "F1shF00d" TO '/tmp/export_DPDEV92.exp' IDENTIFIED BY F1shF00d; 








@?/rdbms/admin/utlrp.sql

select count(*)
from dba_objects
where status = 'INVALID';



**** Apply Patch *******

Download patch or copy from lower environment



--Unzip files
cd   /orastage/u177/Ora12102_stage
    
unzip p18459080_121024_Generic.zip

export PATH=$PATH:$ORACLE_HOME/OPatch


cd /orastage/u177/Ora12102_stage/18459080

opatch prereq CheckConflictAgainstOHWithDetail -ph ./ 


Invoking prereq "checkconflictagainstohwithdetail"

Prereq "checkConflictAgainstOHWithDetail" passed.



. ~/.profile

DPUAT91

sqlplus / as sysdba

shutdown immediate;

exit

lsnrctl stop DPUAT91

. ~/.profile

DPUAT92

sqlplus / as sysdba

shutdown immediate;

exit

lsnrctl stop DPUAT92









cd /orastage/u177/Ora12102_stage/18459080

export PATH=$PATH:$ORACLE_HOME/OPatch

opatch apply

$ORACLE_HOME/OPatch/opatch lsinventory -patch | grep "applied on" | sort


. ~/.profile

DPUAT91

sqlplus / as sysdba

startup

exit

lsnrctl start DPUAT91


. ~/.profile

DPUAT92

sqlplus / as sysdba

startup

exit

lsnrctl start DPUAT92



# Backup  Wallet
30 02 * * * /u01/app/oracle/tls/encrypt/backup_wallet_dir_to_tsm.ksh DPUAT92 >/dev/null 2>&1

40 02 * * * /u01/app/oracle/tls/encrypt/backup_wallet.ksh DPUAT92 > /dev/null 2



scp /u01/app/oracle/tls/encrypt/backup_wallet_dir_to_tsm.ksh dppqa:/u01/app/oracle/tls/encrypt/backup_wallet_dir_to_tsm.ksh 
scp /u01/app/oracle/tls/encrypt/backup_wallet.ksh dppqa:/u01/app/oracle/tls/encrypt/backup_wallet.ksh

cd /u01/app/oracle/tls/encrypt

vi backup_wallet.ksh


/opt/u11/wallet_backup/${DBName}/"


/u10/wallet_backup/DPUAT92

ADMINISTER KEY MANAGEMENT BACKUP KEYSTORE USING 'peoplesoft' IDENTIFIED BY F1shF
00d TO '${BACKUPDIR}';
EOF

ADMINISTER KEY MANAGEMENT BACKUP KEYSTORE USING 'peoplesoft_backup_DPUAT92' IDENTIFIED BY F1shF00d TO '/u10/wallet_backup/DPUAT92/';

#${SCRDIR}/amail.ksh -t "See Attached" -a "${OLOGNAME}" -s "${DBName} Wallet Bac
kup On ${HOST}" -c "bermane@aetna.com" schloendornt@aetna.com



***********************************


SQLNET.ENCRYPTION_TYPES_SERVER= (AES128)
SQLNET.ENCRYPTION_SERVER = requested


SQLNET.ENCRYPTION_TYPES_CLIENT = (3DES168)


SQLNET.ENCRYPTION_TYPES_SERVER= (3DES168)