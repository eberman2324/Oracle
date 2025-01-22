spool check_times.out

SELECT DO.obj# d_obj,DO.name d_name, DO.TYPE# d_type,
po.obj# p_obj,po.name p_name,
TO_CHAR(p_timestamp,'DD-MON-YYYY HH24:MI:SS')
"P_Timestamp",
TO_CHAR(po.stime ,'DD-MON-YYYY HH24:MI:SS') "STIME",
DECODE(SIGN(po.stime-p_timestamp),0,'SAME','*DIFFER*') X
FROM sys.obj$ DO, sys.dependency$ d, sys.obj$ po
WHERE P_OBJ#=po.obj#(+)
AND D_OBJ#=DO.obj#
AND DO.status=1 /*dependent is valid*/
AND po.status=1 /*parent is valid*/
AND po.stime!=p_timestamp /*parent timestamp not match*/
ORDER BY 2,1;

spool off;
