
DECLARE  
 CURSOR C1 IS
 SELECT replace(user_logon,'a','A') as newlogon,user_id
 FROM s_Security s,s_employee e
 WHERE e.person_id = s.person_id and 
      e.company_id = 101 
      and active = 'T' and
      ( user_logon like 'a1%'   or  user_logon like 'a2%' or user_logon like 'a3%' or user_logon like 'a4%' or user_logon like 'a5%' or user_logon like 'a6%' or user_logon like 'a7%' or user_logon like 'a8%' or user_logon like 'a9%');

BEGIN
   update s_security
   set user_logon = user_logon || 'old'
   where user_id in ( select user_id from s_security where
   user_logon in (SELECT replace(user_logon,'a','A') as newlogon
   FROM s_Security s,s_employee e
   WHERE e.person_id = s.person_id and 
      e.company_id = 101 and active = 'T' and
      ( user_logon like 'a1%'   or  user_logon like 'a2%' or user_logon like 'a3%' or user_logon like 'a4%' or user_logon like 'a5%' or user_logon like 'a6%' or user_logon like 'a7%' or user_logon like 'a8%' or user_logon like 'a9%')));
      
   FOR c1_rec IN C1 LOOP
       UPDATE s_security 
       set user_logon = c1_rec.newlogon
       where user_id = c1_rec.user_id;
           
     COMMIT; 
     
   END LOOP;
 
   COMMIT;
END;
