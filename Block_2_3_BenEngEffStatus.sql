-- Update Aetna migrated payments from Approved to Suspended
DECLARE

CURSOR C1 IS
              
select r.pay_req_id
  from beneng.beneng_payment_rqst   r,
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

BEGIN
   
   FOR c1_rec IN C1 LOOP

Update beneng.BENENG_PAYMENT_RQST bpr
   set bpr.eff_status = 'S'
 where bpr.pay_req_id = c1_rec.pay_req_id
 ;
 
      COMMIT;
          
END LOOP;
 
END;
/
