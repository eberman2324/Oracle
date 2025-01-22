-- Created on 12/19/2018 by N821331.....
--Purpose: To activate NEWCO parm for companies (to enable read only functionality) 
--         in 'A' status in z_migr_control table.
DECLARE
  cp_exist INTEGER DEFAULT 0;

  CURSOR CP_cursor IS
    SELECT mc.company_id
      FROM z_migr_control mc, s_company c
     WHERE mc.company_id is NOT NULL
       AND mc.company_id = c.company_id
       AND upper(mc.ctrl_prcss_cd) = 'A';
BEGIN
  FOR CP_record IN CP_cursor LOOP
    cp_exist := 0;
    SELECT COUNT(*)
      INTO cp_exist
      FROM s_company_parms cp, s_company c
     WHERE UPPER(CP.COMPANY_PARMS_CODE) = 'NEWCO'
       AND cp.company_id = c.company_id
       AND cp.company_id = CP_record.company_id;
  
    IF cp_exist = 0 THEN
      INSERT INTO s_company_parms
        (COMPANY_ID,
         PARM_CATEGORY,
         PARM_NAME,
         PARM_AMOUNT,
         UNIT_ID,
         PARM_TEXT,
         PARM_DESCRIPTION,
         COMPANY_PARMS_CODE,
         COMPANY_PARMS_ID,
         CREATE_DATE,
         EDIT_DATE,
         CREATE_USER_ID,
         EDIT_USER_ID,
         COMPANY_PARMS_TEMPLATE_ID,
         MANUAL_FLAG)
      VALUES
        (CP_record.company_id,
         'Client Configuration',
         'NEWCO',
         0,
         0,
         TO_CHAR(SYSDATE, 'mm/dd/yyyy'),
         '',
         'NEWCO',
         SEQ_COMPANY_PARMS.NEXTVAL,
         SYSDATE,
         SYSDATE,
         28,
         28,
         21316,
         null);
      COMMIT;
    ELSE
      UPDATE s_company_parms CP
         SET CP.PARM_TEXT    = TO_CHAR(SYSDATE, 'mm/dd/yyyy'),
             CP.EDIT_USER_ID = 28,
             CP.EDIT_DATE    = SYSDATE
       WHERE UPPER(CP.COMPANY_PARMS_CODE) = 'NEWCO'
         AND CP.COMPANY_ID = CP_record.company_id;
      COMMIT;
    END IF;
    COMMIT;
  END LOOP;
END;
/
