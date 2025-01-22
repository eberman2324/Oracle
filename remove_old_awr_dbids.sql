-- Do not aleter this scipt, it is used in standard build processing.
-- In order to make use of this script, your database must be at 12.1.0.2.170718 or higher.


DECLARE
   current_dbid NUMBER;
   CURSOR old_dbids IS
      SELECT DISTINCT dbid
        FROM DBA_FEATURE_USAGE_STATISTICS
       WHERE dbid NOT IN (SELECT dbid FROM v$database);
BEGIN
   FOR old_dbid IN old_dbids LOOP
      -- Remove old Workload Repository data
--     DBMS_SWRF_INTERNAL.UNREGISTER_REMOTE_DATABASE(old_dbid.dbid);
      DBMS_SWRF_INTERNAL.UNREGISTER_DATABASE(old_dbid.dbid);
   END LOOP;

   /* The third letter of each table name signifies the type of data that it contains.
   . I . advisory functions (SQL Advice, Space Advice, etc)
   . M . metadata information
   . H . historical data
   */

   SELECT dbid INTO current_dbid FROM v$database;

   DELETE FROM wri$_dbu_usage_sample WHERE dbid != current_dbid;
   DELETE FROM wri$_dbu_feature_usage WHERE dbid != current_dbid;
   DELETE FROM wri$_dbu_high_water_mark WHERE dbid != current_dbid;

   /* To turn off Feature Usage and HWM collection
   delete from WRI$_DBU_FEATURE_METADATA;
   delete from WRI$_DBU_HWM_METADATA;
   */

   /* To turn back on Feature Usage and HWM collection
   DBMS_FEATURE_REGISTER_ALLFEAT;
   DBMS_FEATURE_REGISTER_ALLHWM;
   */

   DELETE FROM wri$_dbu_cpu_usage WHERE dbid != current_dbid;
   DELETE FROM wri$_dbu_cpu_usage_sample WHERE dbid != current_dbid;

   COMMIT;

END;
/
