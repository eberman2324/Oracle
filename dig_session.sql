column  sample_time     Heading "Session_History_Sample_Time"           format a40
column  start_time      Heading "EXECUTION_START_TIME"          format a40
column  exec_secs       Heading "EXECUTE_TIME_IN_SECONDS"       Format a40
column  event           heading "Event_________________________"        format a40
column  program         Heading "Program__________________________________________"   format a48
column  module          Heading "Module________________________"        format a40
column  action          Heading "Action________________________"        format a40
column  "DB USER"       format a8
column client_id        format a10
column machine          format a28

set lines 500

select
        session_id,
        session_serial#,
        sample_time,
        substr(to_char(sql_exec_start, 'DD-MON-YY HH24:MI:SS'),1,55) as start_time,
        (sample_time-SQL_EXEC_START) as exec_secs,
        event,
        sql_id,
        program,
        module,
        action,
    decode (user_id, 213,'Apps',268,'PHC_RXP',user_id) "DB USER",
    client_id,
    machine,
    SESSION_STATE,
   TIME_WAITED,
    BLOCKING_SESSION_STATUS,
    BLOCKING_SESSION,
    BLOCKING_SESSION_SERIAL#,
    BLOCKING_INST_ID,
    BLOCKING_HANGCHAIN_INFO,
    CURRENT_OBJ#,
    CURRENT_FILE#,
    CURRENT_BLOCK#
from
        v$active_session_history a
--      dba_hist_active_sess_history a
where
/*
        ( (session_id = 2544 and session_serial#=35925) OR
        (SESSION_ID = 461  AND SESSION_SERIAL#=17309) )
        (session_id = 4330 and session_serial#=14809)
        session_id = 4330
        session_serial#= 14809
*/
        (
        --(session_id = 258 and session_serial#=12875)
	(session_id = 547 and session_serial#=62695)
        --OR (session_id = 1866 and session_serial#=5409)
        )
        and (program not like 'rman%' and program not like 'orac%')
--      and snap_id > 32468
order by
        exec_secs
;

