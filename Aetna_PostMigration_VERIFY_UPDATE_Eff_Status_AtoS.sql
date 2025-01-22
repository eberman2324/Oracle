-- Verify Update to Aetna migrated payments from Approved to Suspended
-- Running this select before the update will return the number of rows to be updated
-- Running this select after the update will return a 0 count
              
select count(r.pay_req_id)
  from beneng_payment_rqst   r,
       s_dis_claim           d,
       s_employee            e,
       wkab10.z_migr_control z
 where r.claim_no = to_char(d.claim_id)
   and d.employee_id = e.employee_id
   and e.company_id = z.company_id
   and r.eff_status = 'A'
   and r.locked_flag = 0
   and z.ctrl_prcss_cd = 'P'
;
