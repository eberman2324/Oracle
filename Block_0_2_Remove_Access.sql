
DECLARE
  --Description: This script is to remove access to internal people for companies which are part of the migration event.

  -- Note: IF these  records NEEDS TO BE REVERTED BACK AFTER MIGRATION EVENT, 
  -- please RUN "1_PROD_Remove_Internal_Companies_Access_Backup.sql" SCRIPT PLEASE BACKUP BELOW SELECT STATEMENT RESULTS....
BEGIN
  ---  Deletes -  PROD : 20681 STG2 : 16862
  DELETE from s_team_access ta
   where ta.team_group_id not in (4582637, 4582635) --PROD: (4582637, 4582635) --STG1 (2897340, 2897341)
     and ta.target_group_id in
         (select g.group_id
            from s_group g
           where g.parent_group_id = 1
             and g.group_type_id = 3
             and g.company_id in
                 (SELECT mc.company_id
                    FROM z_migr_control mc, s_company c
                   WHERE mc.company_id is NOT NULL
                     AND mc.company_id = c.company_id
                     AND upper(mc.ctrl_prcss_cd) = 'A'));
  COMMIT;
END;
/
