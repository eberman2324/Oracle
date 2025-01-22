UPDATE s_security s
SET s.user_logon = user_logon || '_' 
WHERE s.user_logon in
('christopherwilliams');


--- 1 row updated

