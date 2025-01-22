with a as (select dbms_qopatch.get_opatch_lsinventory patch_output from dual)
select max(x.description)
  from a,
       xmltable('InventoryInstance/patches/*'
          passing a.patch_output
          columns
             patch_id number path 'patchID',
             patch_uid number path 'uniquePatchID',
             description varchar2(80) path 'patchDescription'
       ) x
/
