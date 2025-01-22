BEGIN
UPDATE s_report_schedule
set active_lid = 725401 ,
edit_date = sysdate,
edit_user_id = '4591269'
where report_schedule_id in (
Select rs.report_schedule_id
from s_report_schedule rs
join s_employee e on e.EMPLOYEE_ID = rs.EMPLOYEE_ID
join wkab10.Z_migr_control mc on mc.COMPANY_ID = e.COMPANY_ID
where mc.ctrl_prcss_cd='P')
;
Commit;
END;
/
