define DBInstance = &1

@$SCRIPTS/setupenv.sql &DBInstance

set echo off
set feedback off
set serveroutput on size 100000

define Monitor = '&&ScriptsFS/aetna/scripts/monitor';

define Rpt1 = &&Monitor/rpt1.out
define Rpt2 = &&Monitor/rpt2.out
define Rpt3 = &&Monitor/rpt3.out
define Rpt4 = &&Monitor/rpt4.out
define Rpt5 = &&Monitor/rpt5.out
define Rpt6 = &&Monitor/rpt6.out
define Rpt1_daily = &&Monitor/rpt1_daily.out
define Rpt2_daily = &&Monitor/rpt2_daily.out
define Rpt3_daily = &&Monitor/rpt3_daily.out
define Rpt4_daily = &&Monitor/rpt4_daily.out
define Rpt5_daily = &&Monitor/rpt5_daily.out

---
--- Reports run every 5 minutes 
---
spool &&Rpt1
execute dbmonitor.segments_near_max_extents(10)			/* Rpt1 */
spool &&Rpt2
execute dbmonitor.segments_inadequate_room('')			/* Rpt2 */
spool &&Rpt3
execute dbmonitor.invalid_objects_over_threshold(250)		/* Rpt3 */
---execute dbmonitor.invalid_objects_over_threshold(99999)	/* UNLIMITED */
spool &&Rpt4
execute dbmonitor.pinned_objects_under_threshold(0)		/* Rpt4 */
spool &&Rpt5
execute dbmonitor.sessions_blocking_sessions('')		/* Rpt5 */
spool &&Rpt6
execute dbmonitor.security_violations('')			/* Rpt6 */

---
--- Reports run hourly 
---

---
--- Reports run once daily 
---
spool &&Rpt1_daily
execute dbmonitor.dbobjects_changed_today('')			/* Rpt1_daily */
spool &&Rpt2_daily
execute dbmonitor.tablespace_fragmentation_index(30)		/* Rpt2_daily */
spool &&Rpt3_daily
execute dbmonitor.connections_over_threshold(10)		/* Rpt3_daily */
spool &&Rpt4_daily
execute dbmonitor.tablespace_freespace(30)			/* Rpt4_daily */
--- spool &&Rpt5_daily
--- execute dbmonitor.license_highwater_mark('')			/* Rpt5_daily */

spool off


/*-------------------------------------*/
/*   QUIT SQLPLUS  */
quit;
