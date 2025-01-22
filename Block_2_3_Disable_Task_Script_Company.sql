-- Created on 12/19/2018 by N821331 
-- Purpose POST MIGRATION, this script to deactivate tasks for claim migration event companies...
DECLARE
  -- Local variables here
  TASK_SCRIPT     BOOLEAN DEFAULT FALSE;
  TASK_RPT_TYPE   BOOLEAN DEFAULT FALSE;
  TASK_RULESETCOL BOOLEAN DEFAULT FALSE;
  COMM_TEMP       BOOLEAN DEFAULT FALSE;
  cp_exist        INTEGER DEFAULT 0;
  I_STMT          VARCHAR2(4000) := NULL;
  del_cnt         VARCHAR2(4000) := NULL;

  CURSOR CP_cursor IS
    SELECT mc.company_id
      FROM z_migr_control mc
     WHERE mc.company_id is NOT NULL
       AND upper(mc.ctrl_prcss_cd) = 'P';
BEGIN
  FOR CP_record IN CP_cursor LOOP
    --Are there any s_task_script record for current company?
    BEGIN
      --del_cnt = '';
      /*cp_exist := 0;
      SELECT COUNT(*)
        INTO cp_exist
        FROM s_task_script ts, s_company c, t_task t, s_script s
       WHERE ts.company_id = c.company_id
         AND ts.task_id = t.task_id
         AND ts.task_id = s.script_id
         AND ts.company_id = CP_record.company_id;*/
    
      --IF cp_exist > 0 THEN
      delete from s_task_script where company_id = CP_record.company_id;
      TASK_SCRIPT := TRUE;
      --END IF;
    
      del_cnt := 's_task_script deleted ' || SQL%ROWCOUNT;
    EXCEPTION
      WHEN OTHERS THEN
        TASK_SCRIPT := FALSE;
    END;
  
    --Are there any s_task_report_type record for current company?
    BEGIN
      /*cp_exist := 0;
      SELECT COUNT(*)
        INTO cp_exist
        FROM s_task_report_type trt,
             s_company          c,
             t_task             t,
             t_report_type      rt
       WHERE trt.company_id = c.company_id
         AND trt.task_id = t.task_id
         AND trt.report_type_id = rt.report_type_id
         AND trt.company_id = CP_record.company_id;*/
    
      --IF cp_exist > 0 THEN
      delete from s_task_report_type
       where company_id = CP_record.company_id;
      TASK_RPT_TYPE := TRUE;
      --END IF;
      del_cnt := del_cnt || ', s_task_report_type deleted ' || SQL%ROWCOUNT;
    EXCEPTION
      WHEN OTHERS THEN
        TASK_RPT_TYPE := FALSE;
    END;
  
    --Are there any s_task_rulesetcollection record for current company?
    BEGIN
      /*cp_exist := 0;
      SELECT COUNT(*)
        INTO cp_exist
        FROM s_task_rulesetcollection trsc,
             s_company                c,
             s_task                   t,
             t_rule_set_collection    rsc
       WHERE trsc.company_id = c.company_id
         AND trsc.task_id = t.task_id
         AND trsc.rulesetcollection_id = rsc.rulesetcollection_id
         AND trsc.company_id = CP_record.company_id;*/
    
      --IF cp_exist > 0 THEN
      delete from s_task_rulesetcollection
       where company_id = CP_record.company_id;
      TASK_RULESETCOL := TRUE;
      --END IF;
      del_cnt := del_cnt || ', s_task_rulesetcollection deleted ' || SQL%ROWCOUNT;
    EXCEPTION
      WHEN OTHERS THEN
        TASK_RULESETCOL := FALSE;
    END;
  
    --Are there any s_comm_templates record for current company?
    BEGIN
      /*      cp_exist := 0;
      SELECT COUNT(*)
        INTO cp_exist
        FROM s_comm_templates ct, s_company c, t_task t
       WHERE ct.editor_company_id = c.company_id
         AND ct.editor_task_id = t.task_id
         AND ct.editor_company_id = CP_record.company_id;*/
    
      --IF cp_exist > 0 THEN
      delete from s_comm_templates
       where editor_company_id = CP_record.company_id;
      COMM_TEMP := TRUE;
      --END IF;
      del_cnt := del_cnt || ', s_comm_templates deleted ' || SQL%ROWCOUNT;
    EXCEPTION
      WHEN OTHERS THEN
        COMM_TEMP := FALSE;
    END;
 
    --either commit/rollback?
    I_STMT := NULL;
    if (TASK_SCRIPT = TRUE and TASK_RPT_TYPE = TRUE) and
       TASK_RULESETCOL = TRUE and COMM_TEMP = TRUE then
      
       del_cnt := del_cnt || ' for company_id = ' || CP_record.company_id;
       
       I_STMT := 'INSERT INTO S_WKAB_LOGGER_ERROR(WKAB_LOGGER_ERROR_ID,ERROR_MESSAGE,SERVER_NAME,ERROR_ASSEMBLY,ERROR_METHOD,
                                                 ERROR_METHOD_CLASS,CREATE_DATE,CREATE_USER_ID) values (:1,:2,:3,:4,:5,:6,:7,:8)';
      EXECUTE IMMEDIATE I_STMT
        USING SEQ_WKAB_LOGGER_ERROR.NEXTVAL, del_cnt, 'MIGRATIONEVENT', 'DBASTOREDPROCEDURE', 'DBASTOREDPROCEDURE', 'DBASTOREDPROCEDURE', SYSDATE, 28;
        
      COMMIT;
    else
      ROLLBACK;
    
      I_STMT := 'INSERT INTO S_WKAB_LOGGER_ERROR(WKAB_LOGGER_ERROR_ID,ERROR_MESSAGE,SERVER_NAME,ERROR_ASSEMBLY,ERROR_METHOD,
                                                 ERROR_METHOD_CLASS,CREATE_DATE,CREATE_USER_ID) values (:1,:2,:3,:4,:5,:6,:7,:8)';
      EXECUTE IMMEDIATE I_STMT
        USING SEQ_WKAB_LOGGER_ERROR.NEXTVAL, CP_record.company_id, 'MIGRATIONEVENT', 'DBASTOREDPROCEDURE', 'DBASTOREDPROCEDURE', 'DBASTOREDPROCEDURE', SYSDATE, 28;
      COMMIT;
    end if;
  END LOOP;
END;
/
