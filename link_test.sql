spool linktest.out
set echo on
set termout on
set trimspool on

prompt "Testing Valid DPDEV89 Public Links"
connect system@dpdev89

select 1 from dual@DPPRD02.WORLD;
select 1 from dual@DPQA89.WORLD;
select 1 from dual@DRDV01.WORLD;
select 1 from dual@WKABDEV.WORLD;

prompt "Testing Valid DPD3 Public Links"
connect system@dp3

select 1 from dual@WKABUAT.WORLD;
select 1 from dual@DRQA01.WORLD;
select 1 from dual@DRDV01.WORLD;

prompt "Testing Valid DPD3 SYSADM Links"
-- sysadm password not available
--connect sysadm@dp3

--select 1 from dual@DPUPG01.WORLD;
--select 1 from dual@DPPRD01_A.WORLD;
--select 1 from dual@DPDMO02.WORLD;
--select 1 from dual@DPDEV89.WORLD;


***Login wkabuat as system

select 1 from dual@DPQA89.WORLD;

