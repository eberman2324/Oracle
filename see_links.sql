col owner	heading	'Owner'		format a16
col link	heading 'DB Link'	format a30
col user	heading 'User' 		format a16
col host	heading 'Host'		format a18
col Created	heading "Date Created"	format a26

set lines 	120

spool current_links.output


select 
	substr(owner,1,14) "Owner",
	substr(db_link,1,30) "Link",
	substr(username, 1,14) "User",
	substr(host,1,17) "Host",
	substr(to_char(created, 'DD-MON-YY HH24:MI:SS'),1,25) "Created"
from 
	dba_db_links;


spool off;

