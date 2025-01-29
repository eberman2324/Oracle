STARTUP NOMOUNT pfile=/workability/orabin/v920/dbs/initwkabtrg1.ora
CREATE CONTROLFILE SET DATABASE "WKABTRG1" RESETLOGS  ARCHIVELOG
    MAXLOGFILES 15
    MAXLOGMEMBERS 3
    MAXDATAFILES 200
    MAXINSTANCES 1
    MAXLOGHISTORY 25865
LOGFILE
  GROUP 1 (
    '/workability3/wkabtrg1/oracle/oradata/redo01a.log',
    '/workability3/wkabtrg1/oracle/oradata/redo01b.log'
  ) SIZE 5M,
  GROUP 2 (
    '/workability3/wkabtrg1/oracle/oradata/redo02a.log',
    '/workability3/wkabtrg1/oracle/oradata/redo02b.log'
  ) SIZE 5M,
  GROUP 3 (
    '/workability3/wkabtrg1/oracle/oradata/redo03a.log',
    '/workability3/wkabtrg1/oracle/oradata/redo03b.log'
  ) SIZE 5M,
  GROUP 4 (
    '/workability3/wkabtrg1/oracle/oradata/redo04a.log',
    '/workability3/wkabtrg1/oracle/oradata/redo04b.log'
  ) SIZE 5M,
  GROUP 5 (
    '/workability3/wkabtrg1/oracle/oradata/redo05a.log',
    '/workability3/wkabtrg1/oracle/oradata/redo05b.log'
  ) SIZE 5M,
  GROUP 6 (
    '/workability3/wkabtrg1/oracle/oradata/redo06a.log',
    '/workability3/wkabtrg1/oracle/oradata/redo06b.log'
  ) SIZE 5M
DATAFILE
  '/workability3/wkabtrg1/oracle/oradata/beneng_data01.dbf',
  '/workability3/wkabtrg1/oracle/oradata/beneng_index01.dbf',
  '/workability3/wkabtrg1/oracle/oradata/ejsadmin01.dbf',
  '/workability3/wkabtrg1/oracle/oradata/fineos_data01.dbf',
  '/workability3/wkabtrg1/oracle/oradata/fineos_data02.dbf',
  '/workability3/wkabtrg1/oracle/oradata/fineos_data03.dbf',
  '/workability3/wkabtrg1/oracle/oradata/fineos_index01.dbf',
  '/workability3/wkabtrg1/oracle/oradata/logminer01.dbf',
  '/workability3/wkabtrg1/oracle/oradata/system01.dbf',
  '/workability3/wkabtrg1/oracle/oradata/tools01.dbf',
  '/workability3/wkabtrg1/oracle/oradata/undotbs01.dbf',
  '/workability3/wkabtrg1/oracle/oradata/users01.dbf',
  '/workability3/wkabtrg1/oracle/oradata/wkab_data01.dbf',
  '/workability3/wkabtrg1/oracle/oradata/wkab_data02.dbf',
  '/workability3/wkabtrg1/oracle/oradata/wkab_data03.dbf',
  '/workability3/wkabtrg1/oracle/oradata/wkab_index01.dbf',
  '/workability3/wkabtrg1/oracle/oradata/wkab_index02.dbf',
  '/workability3/wkabtrg1/oracle/oradata/wkab_index03.dbf',
  '/workability3/wkabtrg1/oracle/oradata/wkab_lob01.dbf'
CHARACTER SET WE8ISO8859P1
;