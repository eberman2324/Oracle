UPDATE S_SECURITY
SET NEWCO_USER_IND = 'Y',
EDIT_DATE = sysdate,
EDIT_USER_ID = '28'
Where person_ID in (Select p.person_id
                    FROM S_PERSON p
                    JOIN S_EMPLOYEE e on e.person_id = p.person_id
                    Join wkab10.z_migr_control mc on mc.COMPANY_ID = e.COMPANY_ID
		    Where mc.CTRL_PRCSS_CD = 'A');
COMMIT;

