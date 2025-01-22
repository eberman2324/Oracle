
declare 
l_username varchar2(30) := 'AUDSYS'; 
l_pwd_piece1 varchar2(20) := lower(substr(dbms_random.string('a',9),1,9)); 
l_pwd_piece2 varchar2(20) := to_char(trunc(dbms_random.value(10,99))); 
l_pwd_piece3 varchar2(5) := upper(dbms_random.string('A',4)); 
l_pwd_piece4 varchar2(2) := '#*'; 
l_pwd varchar2(20); 
l_sql varchar2(200); 

cursor c1 is
   SELECT username
   FROM dba_users 
   WHERE  (PROFILE = 'DEFAULT' or profile='STANDARD') and username not in ('XS$NULL');


begin 
for user_rec in c1
loop
  DBMS_OUTPUT.PUT_LINE (user_rec.username);
  execute immediate 'alter user ' || user_rec.username || ' profile c##standard '; 

end loop;

end; 

