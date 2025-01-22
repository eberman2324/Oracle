
Rem ----- V ----- cut ----- V ----- cut ----- V ----- cut ----- V ----- cut ----- V
set termout off
column timecol new_value timestamp
column spool_extension new_value suffix
SELECT to_char(sysdate,'dd-Mon-yyyy_hh24miss') timecol,'.outt' spool_extension FROM sys.dual;
column output new_value dbname
SELECT value || '_' output FROM v$parameter WHERE name = 'db_name';
set termout on
spool /orahome/u01/app/oracle/local/logs/create_ai_password_validate_v2____&&dbname&&timestamp&&suffix
set echo on
Rem ----- ^ ----- cut ----- ^ ----- cut ----- ^ ----- cut ----- ^ ----- cut ----- ^




DROP SEQUENCE AEDBA.STRONG_LOG_SEQ
/
CREATE SEQUENCE AEDBA.STRONG_LOG_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    NOCYCLE
    CACHE 20
    NOORDER
/
CREATE TABLE C##AEDBA.STRONG_USERS
(
    USERNAME      VARCHAR2(10) NOT NULL,
    EMAIL_ADDRESS VARCHAR2(50)     NULL,
    LAST_NAME     VARCHAR2(50)     NULL,
    FIRST_NAME    VARCHAR2(50)     NULL,
    CONSTRAINT USERNAME_PK
    PRIMARY KEY (USERNAME)
        USING INDEX TABLESPACE AUDIT_SPACE
                    PCTFREE 10
                    INITRANS 2
                    MAXTRANS 255
                    STORAGE(BUFFER_POOL DEFAULT)
    ENABLE
    VALIDATE
)
ORGANIZATION HEAP
TABLESPACE AUDIT_SPACE 
LOGGING
PCTFREE 10
PCTUSED 40
INITRANS 1
MAXTRANS 255
STORAGE(BUFFER_POOL DEFAULT)
NOPARALLEL
NOCACHE
NOROWDEPENDENCIES
/
CREATE TABLE C##AEDBA.STRONG_LOG
(
    ID       NUMBER(6,0)      NULL,
    USERNAME VARCHAR2(30)     NULL,
    VALUE    VARCHAR2(80)     NULL
)
ORGANIZATION HEAP
TABLESPACE AUDIT_SPACE
LOGGING
PCTFREE 10
PCTUSED 40
INITRANS 1
MAXTRANS 255
STORAGE(BUFFER_POOL DEFAULT)
NOPARALLEL
NOCACHE
NOROWDEPENDENCIES
/
CREATE OR REPLACE FUNCTION             SYS.AI_PASSWORD_VALIDATE_V2
(username varchar2,
  password varchar2,
  old_password varchar2)
  RETURN boolean IS
   n boolean;
   m integer;
   differ integer;
   isdigit boolean;
   ischar  boolean;
   ispunct boolean;
   digitarray varchar2(20);
   punctarray varchar2(25);
   Uchararray varchar2(26);
   Lchararray varchar2(26);
   -- digitpunctarray varchar2(40);
-- -----------------------------------------------------------------------------------------------------------------------------------
   old_pwd varchar2(30);                                                                                   -- --
   new_pwd varchar2(30);                                                                                   -- --
-- -----------------------------------------------------------------------------------------------------------------------------------
  procedure howstrong( username_in varchar2, value_in varchar2)  is                                        -- --
    pragma autonomous_transaction;                                                                         -- --
  begin                                                                                                    -- --
    insert into aedba.strong_log (id, username, value) values (aedba.strong_log_seq.nextval, username_in, value_in);   -- --
    commit;                                                                                                -- --
  end;                                                                                                     -- --
-- -----------------------------------------------------------------------------------------------------------------------------------
BEGIN
   digitarray:= '0123456789';
   Uchararray:= 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
   Lchararray:= 'abcdefghijklmnopqrstuvwxyz';
   punctarray:='!"#$%&()``*+,-/:;<=>?_';
   -- digitpunctarray:= '0123456789!"#$%&()``*+,-/:;<=>?_';

-- -----------------------------------------------------------------------------------------------------------------------------------
   howstrong(username, '***************************************************************************');     -- --
   howstrong(username, '===> '||to_char(sysdate, 'MON-DD-YYYY HH24:MI:SS')||' <===');                      -- --
-- -----------------------------------------------------------------------------------------------------------------------------------
   -- The following lines were used for testing with howstrong...                                          -- --
   -- howstrong(username, '===> OLD PASSWORD: '||old_password);                                               -- --
   -- howstrong(username, '===> NEW PASSWORD: '||password);                                                   -- --
   howstrong(username, '===> Begin Password Strength Checking');                                           -- --
-- -----------------------------------------------------------------------------------------------------------------------------------
   howstrong(username, ' Check if password contains the username');                                        -- --
   -- Check if the password contains the username
   IF ( instr(NLS_LOWER(password), NLS_LOWER(username)) > 0) THEN
     howstrong(username, '!!! -20001   Password contains the username!!!');                                -- --
     raise_application_error(-20001, 'Password contains the username.');
   END IF;

-- -----------------------------------------------------------------------------------------------------------------------------------
   howstrong(username, '  Check for password length < 8');                                                 -- --
   -- Check for the minimum length of the password
   -- howstrong(username, '  Length = '||length(password));                                                   -- --
   IF length(password) < 8 THEN
      howstrong(username, '!!! -20002   Password length less than 8!!!');                                  -- --
      raise_application_error(-20002, 'Password length less than 8.');
   END IF;

-- -----------------------------------------------------------------------------------------------------------------------------------
   howstrong(username, '   Check if the password is too simple.');                                         -- --
   -- Check if the password is too simple. A dictionary of words may be
   -- maintained and a check may be made so as not to allow the words
   -- that are too simple for the password.
   IF NLS_LOWER(password) IN
     ('welcome', 'database', 'account', 'user', 'password', 'oracle',
      'computer', 'abcd',
      'aetna') THEN
      howstrong(username, '!!! -20003   Password too simple!!!');                                          -- --
      raise_application_error(-20003, 'Password too simple.');
   END IF;

-- -----------------------------------------------------------------------------------------------------------------------------------
   howstrong(username, '    Check if the password contains at least one digit');                           -- --
   -- Check if the password contains at least one letter
   -- and one digit (numeric) and one punctuation mark
   -- 1. Check for the digit
   isdigit:=FALSE;
   m := length(password);
   FOR i IN 1..length(digitarray) LOOP
      FOR j IN 1..m LOOP
         IF substr(password,j,1) = substr(digitarray,i,1) THEN
            isdigit:=TRUE;
             GOTO findUchar;
         END IF;
      END LOOP;
   END LOOP;
   IF isdigit = FALSE THEN
      howstrong(username, '!!! -20004   Password should contain at least one digit!!!');                   -- --
      raise_application_error(-20004, 'Password should contain at least one upper character and one lower character and one numeric and one punctuation.');
   END IF;

-- -----------------------------------------------------------------------------------------------------------------------------------
  -- 2a. Check for the upper character
   <<findUchar>>
   howstrong(username, '     Check if the password contains at least one uppercase character');            -- --
   ischar:=FALSE;
   FOR i IN 1..length(Uchararray) LOOP
      FOR j IN 1..m LOOP
         IF substr(password,j,1) = substr(Uchararray,i,1) THEN
            ischar:=TRUE;
             GOTO findLchar;
         END IF;
      END LOOP;
   END LOOP;
   IF ischar = FALSE THEN
      howstrong(username, '!!! -20004   Password should contain at least one uppercase character!!!');     -- --
      raise_application_error(-20004, 'Password should contain at least one upper character and one lower character and one numeric and one punctuation.');
   END IF;

-- -----------------------------------------------------------------------------------------------------------------------------------
  -- 2b. Check for the lower character
   <<findLchar>>
   howstrong(username, '      Check if the password contains at least one lowercase character');           -- --
   ischar:=FALSE;
   FOR i IN 1..length(Lchararray) LOOP
      FOR j IN 1..m LOOP
         IF substr(password,j,1) = substr(Lchararray,i,1) THEN
            ischar:=TRUE;
             GOTO findpunct;
         END IF;
      END LOOP;
   END LOOP;
   IF ischar = FALSE THEN
      howstrong(username, '!!! -20004   Password should contain at least one lowercase character!!!');     -- --
      raise_application_error(-20004, 'Password should contain at least one upper character and one lower character and one numeric and one punctuation.');
   END IF;

-- -----------------------------------------------------------------------------------------------------------------------------------
   -- 3. Check for the punctuation
   <<findpunct>>
   howstrong(username, '       Checking for punctuation in password');                                     -- --
   ispunct:=FALSE;
   FOR i IN 1..length(punctarray) LOOP
      FOR j IN 1..m LOOP
         IF substr(password,j,1) = substr(punctarray,i,1) THEN
            ispunct:=TRUE;
             GOTO endsearch;
         END IF;
      END LOOP;
   END LOOP;
   IF ispunct = FALSE THEN
      howstrong(username, '!!! -20004   Password should contain at least one punctuation mark!!!');        -- --
      raise_application_error(-20004, 'Password should contain at least one upper character and one lower character and one numeric and one punctuation.');
   END IF;
   <<endsearch>>

-- -----------------------------------------------------------------------------------------------------------------------------------
   howstrong(username, '        Checking for password <> old_password by 3 characters');                   -- --
   -- Check if the password differs from the previous password by at least
   -- 3 letters
   IF old_password = '' THEN
      howstrong(username, '!!! -20005   Old password is null!!!');                                         -- --
      raise_application_error(-20005, 'Old password is null.');
   END IF;
   -- Everything is fine; return TRUE ;
-- -----------------------------------------------------------------------------------------------------------------------------------
      old_pwd := upper(old_password);                                                                      -- --
      new_pwd := upper(password);                                                                          -- --
      howstrong(username, '           Old_password is NOT null');                                          -- --
      -- The following lines were used for testing with howstrong...                                       -- --
      -- howstrong(username, '           OLD PASSWORD: '||old_pwd|| ' length(old_pwd) = '||length(old_pwd));  -- --
      -- howstrong(username, '           NEW PASSWORD: '||new_pwd|| ' length(new_pwd) = '||length(new_pwd));  -- --
      -- howstrong(username, '           OLD PASSWORD length(old_pwd) = '||length(old_pwd));                  -- --
      -- howstrong(username, '           NEW PASSWORD length(new_pwd) = '||length(new_pwd));                  -- --
-- -----------------------------------------------------------------------------------------------------------------------------------
   --differ := length(old_password) - length(password);
   differ := abs(length(old_password) - length(password));
   IF abs(differ) < 3 THEN
      IF length(password) < length(old_password) THEN
         m := length(password);
      ELSE
         m := length(old_password);
      END IF;
-- -----------------------------------------------------------------------------------------------------------------------------------
      howstrong(username,'           differ = '||differ||' m = '||m||'   abs(differ) = '||abs(differ));    -- --
-- -----------------------------------------------------------------------------------------------------------------------------------
      --differ := abs(differ);
      FOR i IN 1..m LOOP
          IF substr(password,i,1) != substr(old_password,i,1) THEN
             differ := differ + 1;
          -- howstrong(username,'            old '||i||':'||substr(old_password,i,1));                        -- --
          -- howstrong(username,'            new '||i||':'||substr(password,i,1));                            -- --
          howstrong(username,'             differ = '||differ);                                            -- --
          END IF;
      END LOOP;
      IF differ < 3 THEN
          howstrong(username, '!!! -20005   Password should differ by at least 3 characters.');            -- --
          raise_application_error(-20005, 'Password should differ by at least 3 characters.');
      END IF;
   END IF;
   -- Everything is fine; return TRUE ;
   howstrong(username, '===> End Password Strength Checking.  Password sucessfully changed!');             -- --
   RETURN(TRUE);
END;
/

