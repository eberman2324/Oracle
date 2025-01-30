set echo on
spool /oradb/app/oracle/admin/HEPYGOLD/create/CreateDB.log

startup nomount pfile="/oradb/app/oracle/product/19.22.0/db_1/dbs/initHEPYGOLD.ora";
CREATE DATABASE HEPYGOLD
USER SYS IDENTIFIED BY "&&sysPassword"
USER SYSTEM IDENTIFIED BY "&&systemPassword"
LOGFILE
	GROUP 1 ('/oradb/app/oracle/admin/HEPYGOLD/redo_a/redo_01a.log','/oradb/app/oracle/admin/HEPYGOLD/redo_b/redo_01b.log') SIZE 5M,
	GROUP 2 ('/oradb/app/oracle/admin/HEPYGOLD/redo_a/redo_02a.log','/oradb/app/oracle/admin/HEPYGOLD/redo_b/redo_02b.log') SIZE 5M,
	GROUP 3 ('/oradb/app/oracle/admin/HEPYGOLD/redo_a/redo_03a.log','/oradb/app/oracle/admin/HEPYGOLD/redo_b/redo_03b.log') SIZE 5M
    MAXLOGFILES 15
    MAXLOGMEMBERS 3
    MAXDATAFILES 300
    MAXINSTANCES 1
    MAXLOGHISTORY 25865
    NOARCHIVELOG
CHARACTER SET WE8MSWIN1252
NATIONAL CHARACTER SET AL16UTF16
DATAFILE '/oradb/app/oracle/admin/HEPYGOLD/data/system_01.dbf' SIZE 50M AUTOEXTEND ON NEXT  10240K MAXSIZE UNLIMITED  extent management local
SYSAUX DATAFILE '/oradb/app/oracle/admin/HEPYGOLD/data/sysaux01.dbf' SIZE 50M AUTOEXTEND ON NEXT  10240K MAXSIZE UNLIMITED 
DEFAULT TEMPORARY TABLESPACE TEMP TEMPFILE '/oradb/app/oracle/admin/HEPYGOLD/data/temp01.dbf' SIZE 50M AUTOEXTEND ON NEXT 640K MAXSIZE  5000M  
UNDO TABLESPACE "UNDOTBS1" DATAFILE '/oradb/app/oracle/admin/HEPYGOLD/data/undotbs1.dbf' SIZE 50M AUTOEXTEND ON NEXT  5120K MAXSIZE UNLIMITED;
spool off