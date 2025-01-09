--CONSTRAINT_TYPE
  --R  = Foreign Key

select * from dba_constraints where owner  = 'WKAB10' and  CONSTRAINT_TYPE = 'R'
and R_constraint_name like '%PK_REQ%'
 order by table_name
 

-- This query will return tables that have FK over to (referencing) particular table
-- In case of T_SECURITY when somebody wants to delete records it will go and delete them from child table
-- And if no indexes in child table on that field or index with multiple fields with this field first
-- This could produce blocking locks. So remedy is to create Index on table with FK in this case T_LEAVE
SELECT table_name 
  FROM ALL_CONSTRAINTS 
 WHERE constraint_type = 'R' -- "Referential integrity" 
   AND r_constraint_name IN ( 
           SELECT constraint_name 
             FROM ALL_CONSTRAINTS 
            WHERE table_name = 'T_SECURITY' 
              AND constraint_type IN ('U', 'P') -- "Unique" or "Primary key" 
         ) 
         
       
--T_ALTERNATE_EMAIL
--T_LEAVE
--T_PROFILE_GENTASK
--T_PROFILE_TASK_FILTER
--T_PROFILE_TASK_LISTS
--T_EMPLOYEE_REGULATION_SCOPE
--T_EMPLOYEE_REGULATION_SCOPE
--T_ALPHA_SPLIT
--T_AUDIT



***********************************************************************


Yes.  Because of the way the database evolved I guess, they haven't always created the foreign key constraints, so it won't be a complete list.  But, you can get it like...:
 
select cf.owner, cf.constraint_name, 
       cf.table_name, cf.r_owner, cf.r_constraint_name,
       cp.owner as r_table_owner, cp.table_name as r_table_name,
       cpcc.position, cast(cpcc.column_name as varchar2(30))  as column_name
from dba_constraints cf,
     dba_constraints cp,
     dba_cons_columns cpcc
where cf.r_owner = cp.owner
  and cf.r_constraint_name = cp.constraint_name
  and cpcc.owner = cp.owner
  and cpcc.constraint_name = cp.constraint_name
  and cf.constraint_type='R'
  and cf.owner in ('BENENG', 'WKAB10')
order by 1,2,8
/

The way it works is that a foreign key constraint depends on a primary key constraint.  So in the query, the "constraint_name" is the foreign key constraint on "table_name" and the "r_constraint_name" is the primary key constraint on "r_table_name" that it refers to.  


--------------------------------------------------------------------------------
From: Aceto, Robert A 
Sent: Wednesday, September 15, 2010 3:25 PM
To: Swafford, Mike; Berman, Eugene
Cc: Verma, Raj
Subject: querying for foreign keys and constraints


Hey guys,
 
We are doing some research to determine which tables need to be included in the archiving for the various pieces 
(claims, employees, companies) and short of doing the manual research, is there a way we can query for tables that have a foreign key or constraint with other tables.
 
Thank you for any help you can provide!


