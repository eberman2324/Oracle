set trimspool on line 200 pagesize 0 feed off verify off term off

spool ldap_user_&1..out

select a.first_nm,
       b.last_nm,
       c.email
from
    (
     select distinct trim(attribute_value)||':' as first_nm
     from  table (aedba.ad_pkg.aeth('&1'))
     where attribute_name =  'givenName'
    )a,
    (
     select distinct trim(attribute_value)||':' as last_nm
     from  table (aedba.ad_pkg.aeth('&1'))
     where attribute_name = 'sn'
    )b,
    (
     select distinct trim(attribute_value) as email
     from  table (aedba.ad_pkg.aeth('&1'))
     where attribute_name = 'mail'
    )c
/

spool off

