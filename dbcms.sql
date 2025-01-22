CREATE USER DBCMS
    IDENTIFIED BY VALUES 'BBEE1F9B3A94B3CF'
    DEFAULT TABLESPACE          &&DEFAULT_TABLESPACE
    TEMPORARY TABLESPACE        &&TEMPORARY_TABLESPACE 
    PROFILE                     AETNA_SERVICE_ACCOUNT_PROFILE -- Optional - Use any approved profile with NON expiring Password.
    ACCOUNT                     UNLOCK;

ALTER USER DBCMS QUOTA UNLIMITED ON &&DEFAULT_TABLESPACE;

-- Create role
CREATE ROLE ICR_AUDIT;

-- grant role to user
GRANT ICR_AUDIT TO DBCMS;

-- grant privs to role;
GRANT SELECT_CATALOG_ROLE   TO ICR_AUDIT;
GRANT SELECT ANY DICTIONARY TO ICR_AUDIT;
GRANT CREATE SESSION        TO ICR_AUDIT;

-- grant privs to user. These are used to create a view. 
-- Selects for views must be granted at the user level
/*************************************************************************/ 
/* 11g R2 documentation under Create View                                */
/* "The owner of the schema containing the view must have the privileges */
/* necessary to either select, insert, update, or delete rows from all   */
/* the tables or views on which the view is based. The owner must be     */
/* granted these privileges directly, rather than through a role."       */
/*************************************************************************/ 
GRANT SELECT ON SYS.DEPENDENCY$ TO DBCMS;
GRANT SELECT ON DBA_OBJECTS     TO DBCMS;

-- View only valid on 11g+

CREATE OR REPLACE VIEW DBCMS.WRIP_INVALID_OBJECT_CHECK_V
AS
       SELECT BASE,
              OWNER,
              OBJECT_TYPE,
              OBJECT_NAME,
              DEPENDANT_FLAG,
              ASTATUS,
              BSTATUS
         FROM (SELECT A.OBJECT_ID BASE,
                      B.OBJECT_ID REL,
                      A.OBJECT_NAME,
                      A.OBJECT_TYPE,
                      A.OWNER,
                      'Y' AS DEPENDANT_FLAG,
                      A.STATUS AS ASTATUS,
                      B.STATUS AS BSTATUS
                 FROM DBA_OBJECTS A, DBA_OBJECTS B, SYS.DEPENDENCY$ C
                WHERE     A.OBJECT_ID = C.D_OBJ#
                      AND B.OBJECT_ID = C.P_OBJ#
                      AND (A.STATUS = 'INVALID' OR B.STATUS = 'INVALID')
                      AND NOT A.OBJECT_NAME = B.OBJECT_NAME) OBJECTS
   CONNECT BY BASE = PRIOR REL
     GROUP BY BASE,
              OWNER,
              OBJECT_NAME,
              OBJECT_TYPE,
              DEPENDANT_FLAG,
              ASTATUS,
              BSTATUS
     ORDER BY MAX (LEVEL) DESC;