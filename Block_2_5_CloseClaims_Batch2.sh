#!/bin/ksh
export ORACLE_SID=wkabprod

run_sql()
{
cs=wkab10/`cat $ORACLE_BASE/.wkab10.pw`
   sqlplus /nolog <<-EOF
	connect $cs 
	set trimspool on
	set echo on
	set linesize 1024
	set define off
	set time on
	set timing on
	spool ${1}.out
	@${1}
	exit
	EOF
}
run_sql Block_2_5_2_CloseClaims_TaskInstance_Batch2.sql 

echo done

