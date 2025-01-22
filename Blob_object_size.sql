set serveroutput on
 
DECLARE
 
total_blocks NUMBER;
total_bytes NUMBER;
unused_blocks NUMBER;
unused_bytes NUMBER;
lastextf NUMBER;
last_extb NUMBER;
lastusedblock NUMBER;
 
username varchar2(30);
lobsegname varchar2(30);
 
unformatted_blocks NUMBER;
unformatted_bytes  NUMBER;
fs1_blocks         NUMBER;
fs1_bytes          NUMBER;
fs2_blocks         NUMBER;
fs2_bytes          NUMBER;
fs3_blocks         NUMBER;
fs3_bytes          NUMBER;
fs4_blocks         NUMBER;
fs4_bytes          NUMBER;
full_blocks        NUMBER;
full_bytes         NUMBER;
 
BEGIN
DBMS_SPACE.UNUSED_SPACE('PROD', 'SYS_LOB0000295690C00002$$', 'LOB',
total_blocks,
total_bytes,
unused_blocks,
unused_bytes,
lastextf,
last_extb,
lastusedblock);
 
dbms_output.put_line('--------------------------------------');
dbms_output.put_line('DBMS_SPACE.UNUSED_SPACE LOB');
dbms_output.put_line('--------------------------------------');
 
dbms_output.put_line('total_blocks = '||total_blocks);
dbms_output.put_line('total_bytes = '||total_bytes);
dbms_output.put_line('unused_blocks = '||unused_blocks);
dbms_output.put_line('unused_bytes = '||unused_bytes);
dbms_output.put_line('lastextf = '||lastextf);
dbms_output.put_line('last_extb = '||last_extb);
dbms_output.put_line('lastusedblock = '||lastusedblock);
END;
/