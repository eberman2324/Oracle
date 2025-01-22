create table wkab10.close_claims_emp_work_jun as (
 select employee_id , company_id
FROM s_employee
where company_id in (select company_id from s_migr_control where event_nm = '2020Jun'));
--48 secs 


