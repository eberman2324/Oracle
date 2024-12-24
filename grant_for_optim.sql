set echo on trimspool on 

spool &1._grants_for_optim_service_id.out

GRANT SELECT ON SYS.USER$ TO S022498;
GRANT SELECT ON SYS.ENC$ TO S022498;
 
spool off;

exit



