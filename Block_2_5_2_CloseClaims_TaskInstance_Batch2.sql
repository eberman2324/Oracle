UPDATE wkab10.T_TASK_INSTANCE
SET STATUS = 8002 , --cancelled
SHAREPLEX_IGNORE_IND = 'T',
EDIT_DATE = sysdate,
EDIT_USER_ID = 28
WHERE STATUS not in (8003, 8002)--cancelled , completed
AND  employee_id in ( Select e.EMPLOYEE_ID
                       FROM wkab10.close_claims_emp_work_jun e 
                      where company_id in (500693,11095)
                       ) ;

commit;
