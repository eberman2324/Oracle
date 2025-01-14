set pagesize 0 head off feed off
select (space_used/space_limit) * 100 from v$recovery_file_dest;
