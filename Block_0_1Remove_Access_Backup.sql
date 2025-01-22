create table wkab10.t_team_access_20200626
as
SELECT *
  from wkab10.t_team_access ta
 where ta.team_group_id not in (4582637, 4582635) --PROD: (4582637, 4582635) --STG1 (2897340, 2897341)
   and ta.target_group_id in
       (select g.group_id
          from wkab10.t_group g
         where g.parent_group_id = 1
           and g.group_type_id = 3
           and g.company_id in
               (SELECT mc.company_id
                  FROM wkab10.z_migr_control mc, wkab10.t_company c
                 WHERE mc.company_id is NOT NULL
                   AND mc.company_id = c.company_id
                   AND upper(mc.ctrl_prcss_cd) = 'A'));
