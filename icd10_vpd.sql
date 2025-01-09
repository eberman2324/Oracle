CREATE OR REPLACE FUNCTION aedba.vpd_allowed_users( 
  schema_var IN VARCHAR2,
  table_var  IN VARCHAR2
 )
 RETURN VARCHAR2
 IS
  return_val VARCHAR2 (400);
 BEGIN
  return_val := 'sys_context(''USERENV'', ''SESSION_USER'') in (''A223576'', ''SYSTEM'') ';
  RETURN return_val;
 END vpd_allowed_users;
/
grant execute on aedba.vpd_allowed_users to public
/


BEGIN
  DBMS_RLS.ADD_POLICY (
    object_schema    => 'RESTORE_20120612',
    object_name      => 'A_DIS_CLINICAL',
    policy_name      => 'ICD10_PROD_TEST_POLICY',
    function_schema  => 'AEDBA',
    policy_function  => 'VPD_ALLOWED_USERS',
    statement_types  => 'select, insert, update, delete'
   );
  DBMS_RLS.ADD_POLICY (
    object_schema    => 'RESTORE_20120612',
    object_name      => 'T_DIS_CLINICAL',
    policy_name      => 'ICD10_PROD_TEST_POLICY',
    function_schema  => 'AEDBA',
    policy_function  => 'VPD_ALLOWED_USERS',
    statement_types  => 'select, insert, update, delete'
   );
  DBMS_RLS.ADD_POLICY (
    object_schema    => 'RESTORE_20120612',
    object_name      => 'T_CLAIM_SNAPSHOT',
    policy_name      => 'ICD10_PROD_TEST_POLICY',
    function_schema  => 'AEDBA',
    policy_function  => 'VPD_ALLOWED_USERS',
    statement_types  => 'select, insert, update, delete'
   );
  DBMS_RLS.ADD_POLICY (
    object_schema    => 'RESTORE_20120612',
    object_name      => 'T_DIS_CLAIM',
    policy_name      => 'ICD10_PROD_TEST_POLICY',
    function_schema  => 'AEDBA',
    policy_function  => 'VPD_ALLOWED_USERS',
    statement_types  => 'select, insert, update, delete'
   );
  DBMS_RLS.ADD_POLICY (
    object_schema    => 'RESTORE_20120612',
    object_name      => 'T_LEAVE',
    policy_name      => 'ICD10_PROD_TEST_POLICY',
    function_schema  => 'AEDBA',
    policy_function  => 'VPD_ALLOWED_USERS',
    statement_types  => 'select, insert, update, delete'
   );
 END;
/


