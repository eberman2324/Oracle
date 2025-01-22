
declare

v_userID    number:=28; --who will user id be, 28?
v_closure   date := trunc(sysdate);  --- will need this from Mary
 
BEGIN

/*---  update task instance
UPDATE S_TASK_INSTANCE
SET STATUS = 8002 , --cancelled
SHAREPLEX_IGNORE_IND = 'T',
EDIT_DATE = sysdate,
EDIT_USER_ID = v_userID
WHERE STATUS not in (	8003, 8002)--cancelled , completed
AND  employee_id in ( Select e.EMPLOYEE_ID
                       FROM S_Employee e 
                       JOIN WKAB10.Z_MIGR_CONTROL z on z.COMPANY_ID = e.COMPANY_ID
                       WHERE UPPER(z.CTRL_PRCSS_CD) = 'P' 
                       ) ; 
commit;*/

-- update Staged tasks
Update s_stage_tasks
set Process_status = 1,
processed_date = sysdate
WHERE  employee_id in (Select e.EMPLOYEE_ID
                       FROM S_Employee e 
                       JOIN WKAB10.Z_MIGR_CONTROL z on z.COMPANY_ID = e.COMPANY_ID
                       WHERE UPPER(z.CTRL_PRCSS_CD) = 'P' ) ;
commit;

-- update leave
UPDATE S_LEAVE
SET STATUS_ID = 53002 , -- closed
EDIT_DATE = sysdate,
EDIT_USER_ID = v_userID
WHERE STATUS_ID  = 53001 --open
AND  employee_id in (Select e.EMPLOYEE_ID
                       FROM S_Employee e 
                       JOIN WKAB10.Z_MIGR_CONTROL z on z.COMPANY_ID = e.COMPANY_ID
                       WHERE UPPER(z.CTRL_PRCSS_CD) = 'P' ) ;   
commit;
 
                     
 --- set what bulk closure calls crossover rtw                     
UPDATE S_DIS_RTW
SET RTW_THRU_DATE = v_closure -1, 
edit_date = sysdate, 
edit_user_id = v_userID 
WHERE (RTW_THRU_DATE > v_closure AND RTW_START_DATE < v_closure )-- in force during closure
AND rtw_status_id = 42002
AND RTW_ID in (Select rtw.RTW_ID
                 FROM S_DIS_RTW rtw
                 JOIN S_DIS_CLAIM dc on dc.CLAIM_ID = rtw.CLAIM_ID
                 JOIN S_Employee e on e.EMPLOYEE_ID = dc.EMPLOYEE_ID 
                 JOIN WKAB10.Z_MIGR_CONTROL z on z.COMPANY_ID = e.COMPANY_ID
                 WHERE UPPER(z.CTRL_PRCSS_CD) = 'P');
 commit;  

 --- set future rtw                     
UPDATE S_DIS_RTW
SET rtw_status_id = 42006, 
RTW_REASON_ID = 43001,
edit_date = sysdate, 
edit_user_id = v_userID 
WHERE (RTW_START_DATE > v_closure )-- RTW START IS AFTER CLOSURE
AND RTW_STATUS_ID = 42002
AND RTW_ID in (Select rtw.RTW_ID
                 FROM S_DIS_RTW rtw
                 JOIN S_DIS_CLAIM dc on dc.CLAIM_ID = rtw.CLAIM_ID
                 JOIN S_Employee e on e.EMPLOYEE_ID = dc.EMPLOYEE_ID 
                 JOIN WKAB10.Z_MIGR_CONTROL z on z.COMPANY_ID = e.COMPANY_ID
                 WHERE UPPER(z.CTRL_PRCSS_CD) = 'P');
 commit;  
              
 -- insert rtw closure due to migration
 insert into s_dis_rtw 
            (rtw_id, 
            claim_id, 
            rtw_start_date, 
            rtw_thru_date, 
            rtw_status_id, 
            rtw_reason_id, 
             work_status_id, 
             create_user_id, 
             edit_user_id, 
             create_date, 
             edit_date, 
             modified_minutes_id, 
             modified_hours) 
SELECT  seq_dis_rtw.nextval,
        dc.claim_id,        
        v_closure,
	null,
        42003, -- rtw status
        1629223, -- rtw reason
        null, -- work status id
        v_userID,
        v_userID,
        sysdate, 
        sysdate, 
        124001, 
        0
FROM s_dis_claim dc
JOIN s_employee e on e.employee_id = dc.EMPLOYEE_ID
JOIN WKAB10.Z_MIGR_CONTROL z on z.COMPANY_ID = e.COMPANY_ID
WHERE UPPER(z.CTRL_PRCSS_CD) = 'P'
and CLAIM_STATUS_ID in (32001,32002);  
commit;

-- update dis_claim note this must follow update update rtw else RTW update wont work
UPDATE S_DIS_CLAIM
SET CLAIM_STATUS_ID = 32003 , --closed
EDIT_DATE = sysdate,
EDIT_USER_ID = v_userID,
claim_thru_date = v_closure - 1
WHERE CLAIM_STATUS_ID in (32001,32002)--open pend
AND  employee_id in ( Select e.EMPLOYEE_ID
                       FROM S_Employee e                  
                       JOIN WKAB10.Z_MIGR_CONTROL z on z.COMPANY_ID = e.COMPANY_ID
                       WHERE UPPER(z.CTRL_PRCSS_CD) = 'P' ) ;  
commit;  

--Update pw_mstr_claim
update s_pw_mstr_claim c 
set c.claim_status_lid = 768103, --closed
edit_date = sysdate, 
edit_user_id = v_userID 
WHERE claim_status_lid in (768100,768102)
AND employee_id in (Select e.EMPLOYEE_ID
                       FROM S_Employee e 
                       JOIN WKAB10.Z_MIGR_CONTROL z on z.COMPANY_ID = e.COMPANY_ID
                       WHERE UPPER(z.CTRL_PRCSS_CD) = 'P' );
  commit;        
 
---- PW Determination
DECLARE


cursor PW_Determine is
with PW as (
select dt.claim_id, max(PW_DETERMINATION_ID) as determination
from s_pw_mstr_claim pw
join s_pw_claim p on p.MSTR_CLAIM_ID = pw.CLAIM_ID
join s_pw_determination dt on dt.CLAIM_ID = p.CLAIM_ID
Join s_employee e on e.employee_id = pw.employee_id
JOIN WKAB10.Z_MIGR_CONTROL z on z.COMPANY_ID = e.COMPANY_ID
WHERE UPPER(z.CTRL_PRCSS_CD) = 'P' 
group by dt.claim_id, dt.STATUS_LID)

select distinct p.claim_id 
from PW 
Join S_pw_determination p on p.PW_DETERMINATION_ID = pw.determination
Where p.STATUS_LID in (773500,773501)
;
Begin
  For determination in PW_Determine Loop
    Insert into S_PW_DETERMINATION
        select SEQ_PW_DETERMINATION.nextval, determination.claim_id,773503,1630229, v_closure,sysdate,28,sysdate,28,null,null
    from dual;
    commit;
    
    
   end Loop;

end;

                         
 END;
 /
