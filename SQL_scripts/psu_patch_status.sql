set linesize 360
--
prompt   List of PSUs applied to both the $OH and the DB
--
with a as (select dbms_qopatch.get_opatch_lsinventory patch_output from dual)
 select x.patch_id, x.patch_uid, x.rollbackable, s.status, x.description
   from a,
       xmltable('InventoryInstance/patches/*'
          passing a.patch_output
          columns
             patch_id number path 'patchID',
             patch_uid number path 'uniquePatchID',
             description varchar2(80) path 'patchDescription',
             rollbackable varchar2(8) path 'rollbackable'
       ) x,
       dba_registry_sqlpatch s
 where x.patch_id = s.patch_id
   and x.patch_uid = s.patch_uid
 and s.bundle_series = 'PSU'
 and s.action = 'APPLY';

--
prompt   PSUs installed into the $OH but not applied to the DB
--
with a as (select dbms_qopatch.get_opatch_lsinventory patch_output from dual)
select x.patch_id, x.patch_uid, x.description
  from a,
       xmltable('InventoryInstance/patches/*'
          passing a.patch_output
          columns
             patch_id number path 'patchID',
             patch_uid number path 'uniquePatchID',
             description varchar2(80) path 'patchDescription'
       ) x
minus
select s.patch_id, s.patch_uid, s.description
  from dba_registry_sqlpatch s;


--
prompt   PSUs applied to the DB but not installed into the $OH
--
with a as (select dbms_qopatch.get_opatch_lsinventory patch_output from dual)
select s.patch_id, s.patch_uid, s.description
  from dba_registry_sqlpatch s
  where s.action = 'APPLY' and s.patch_id not in (select s.patch_id from dba_registry_sqlpatch where action = 'ROLLBACK')
minus
select x.patch_id, x.patch_uid, x.description
  from a,
       xmltable('InventoryInstance/patches/*'
          passing a.patch_output
          columns
             patch_id number path 'patchID',
             patch_uid number path 'uniquePatchID',
             description varchar2(80) path 'patchDescription'
       ) x;


