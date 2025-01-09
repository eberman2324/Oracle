-- Not recommen to use WHERE TO_CHAR(
SELECT ERROR_LOG_ID,CREATE_DATE, ERR_DESC FROM S_ERROR_LOG WHERE TO_CHAR(CREATE_DATE,'MM/DD/YYYY')  =  '08/06/2009' ORDER BY CREATE_DATE DESC;

-- This is more efficient way
SELECT ERROR_LOG_ID,TO_CHAR(CREATE_DATE,'MM/DD/YYYY HH24:MI'), ERR_DESC  FROM S_ERROR_LOG
 WHERE CREATE_DATE =  to_date('10/26/2009', 'MM/DD/YYYY')  and ERR_DESC like '%MVMPWKUTLAP11%'


--More examples for date usage

-- Uses ship_date index 

where ship_date >= trunc(sysdate-7) + 1;


-- Uses ship_date index

where ship_date = to_date(‘2004-01-04’,’YYYY-MM-DD’);