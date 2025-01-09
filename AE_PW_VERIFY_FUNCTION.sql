CREATE OR REPLACE FUNCTION "SYS"."AE_PW_VERIFY_FUNCTION" 
(
  username     IN varchar2,
  password     IN varchar2,
  old_password IN varchar2
)
return boolean
--return number
is
type message_t is table of varchar2(128) index by PLS_INTEGER;
l_messages message_t;
l_pw_message varchar2(256) := 'PW Rejected: ';

-- List of allowed characters
l_non_alpha varchar2(256) := '-~`!@#$%^&*()_+={}|:;"<>,.?/';

l_complexity_count PLS_INTEGER :=0;
l_fatal_errors PLS_INTEGER :=0;

l_seg_repeats boolean:=FALSE;

begin
-- Aetna Rules:
-- Password must be greater than 8 characters
-- Can't match the user-id
-- Password must also meet 3 of the following criteria
-- 1) Contains english uppercase characters (A through Z)
-- 2) Contains english lowercase characters (a through z)
-- 3) Contains numbers (0 through 9)
-- 4) Contains non-alphanumeric character (such as: $, @, #, %)
-- Additional Rules:
-- 1) Can't be the userername even in mixed case (more stringent than above).
-- 2) Can't re-use any segment of the old password 3-characters or larger

   -- Must contain one lower case letter
   if regexp_instr(password, '[a-z]') = 0
   then
      l_messages(1):='Need lower-case';
   else
      l_complexity_count := l_complexity_count + 1;
   end if;

   -- One Upper case letter
   if regexp_instr(password, '[A-Z]') = 0
   then
      l_messages(2):='Need upper-case';
   else
      l_complexity_count := l_complexity_count + 1;
   end if;

   -- One non-alpha
   if regexp_instr(password, '[' || l_non_alpha || ']') = 0
   then
      l_messages(3):='Need non-alpha (' || l_non_alpha || ')';
   else
      l_complexity_count := l_complexity_count + 1;
   end if;

   -- One number
   if regexp_instr(password, '[0-9]') = 0
   then
      l_messages(4):='Need numeric';
   else
      l_complexity_count := l_complexity_count + 1;
   end if;

   -- Can't be same as username
   if upper(password) = upper(username)
   then
      l_messages(5):='Not username';
      l_fatal_errors := l_fatal_errors + 1;
   end if;

   -- Differs more than 3 chars from the old
/*   if length(old_password) > 3) and regexp_instr(password, '[' || old_password || ']{' || (length(old_password)-3) || '}')
   then
      l_messages(6):='Too similar to old';
   else
      l_complexity_count := l_complexity_count + 1;
   end if;
*/

   -- 3-char piece of old password repeated
   -- Note:  This cannot be checked for DBA's altering a users password since
   --        they don't supply an old password.
   for i in 1 .. (nvl(length(old_password), 0) - 2)
   loop
     if instr(password, substr(old_password, i, 3)) > 0
     then
        l_seg_repeats := TRUE;
        exit;
     end if;
   end loop;

   if l_seg_repeats
   then
      l_messages(6):='3-Char segment of old pw repeated';
      l_fatal_errors := l_fatal_errors + 1;
   end if;

   -- Length at least 8
   if length(password) < 8
   then
      l_messages(7):='At least 8 chars';
      l_fatal_errors := l_fatal_errors + 1;
   end if;

   --dbms_output.put_line('==> ' || l_complexity_count);
   if l_fatal_errors > 0 or l_complexity_count < 3
   then
      for i in l_messages.first .. l_messages.last
      loop
         if l_messages.exists(i)
         then
            l_pw_message := l_pw_message || ' -' || l_messages(i);
         end if;
      end loop;
      raise_application_error(-20001, l_pw_message);
   end if;

   -- Everything is fine; return TRUE ;
   return(true);
   --return 0;
end;
/