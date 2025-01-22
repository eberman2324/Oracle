set trimspool on

spool &1._create_optim_package.out

set echo on 

/*--------------------------------------------------------------------*
  *  Oracle9i package used by Catalog Services for Creator Names.      *
  *--------------------------------------------------------------------*/
  CREATE OR REPLACE PACKAGE S022498.PSTO1IV0100_CSSCID AS
/*--------------------------------------------------------------------*
  *  Declare the PL/SQL Tables used by the Procedures in this package  *
  *--------------------------------------------------------------------*/
    TYPE t_creatorname   IS TABLE OF SYS.USER$.NAME%TYPE
          INDEX BY BINARY_INTEGER;
    TYPE t_creatornum    IS TABLE OF SYS.USER$.USER#%TYPE
          INDEX BY BINARY_INTEGER;

 /*--------------------------------------------------------------------*
  *  Procedure used to acquire Creator Names when pattern is an        *
  *  explicit value.                                                   *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSGETCIDLIST0
    (RowsToGet             IN INTEGER,
     CidPatternIn          IN VARCHAR2,
     CreatorName          OUT t_creatorname,
     CreatorNum           OUT t_creatornum);

 /*--------------------------------------------------------------------*
  *  Procedure used to acquire Creator Names when pattern is a         *
  *  generic value.                                                    *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSGETCIDLIST1
    (RowsToGet             IN INTEGER,
     CidPatternIn          IN VARCHAR2,
     CreatorName          OUT t_creatorname,
     CreatorNum           OUT t_creatornum);
  END PSTO1IV0100_CSSCID;
/



