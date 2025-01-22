spool create_OPTIM_user_${ORACLE_SID}.out


CREATE OR REPLACE EDITIONABLE PACKAGE S022498.PSTO1IV0100_CSSCHECK  AS
 /*--------------------------------------------------------------------*
  *  Declare the PL/SQL Tables used by the Procedures in this Package  *
  *--------------------------------------------------------------------*/
    TYPE t_cnm     IS TABLE OF SYS.CON$.NAME%TYPE
          INDEX BY BINARY_INTEGER;
    TYPE t_int        IS TABLE OF INTEGER
          INDEX BY BINARY_INTEGER;
    TYPE t_chr        IS TABLE OF CHAR(1)
          INDEX BY BINARY_INTEGER;
 
 /*--------------------------------------------------------------------*
  *  Procedure used to acquire Basic Check data from CON$,CDEF$,CCOL$  *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSGETCHECK
    (RowsToGet             IN INTEGER,
     ObjectNumIn           IN INTEGER,
     ConName              OUT t_cnm,
     ConId                OUT t_int,
     ColId                OUT t_int,
     Enabled              OUT t_int,
     TextLen              OUT t_int,
     Deferable            OUT t_chr,
     DeferInit            OUT t_chr,
     Validated            OUT t_chr);
 
 /*--------------------------------------------------------------------*
  *  Procedure used to acquire Check text from CDEF$                   *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSEXPCHECK
    (RowsToGet             IN INTEGER,
     ObjectNumIn           IN INTEGER,
     OffsetNumIn           IN INTEGER,
     ColumnNumIn           IN INTEGER, /* not used */
     CheckText            OUT VARCHAR2);
 
 /*--------------------------------------------------------------------*
  *  Procedure used to acquire Supplemntal Log Groups                  *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSGETSUPPL
    (RowsToGet             IN INTEGER,
     ObjectNumIn           IN INTEGER,
     ConName              OUT t_cnm,
     ConId                OUT t_int,
     ColId                OUT t_int,
     DeferInit            OUT t_chr);
  END PSTO1IV0100_CSSCHECK;
/
CREATE OR REPLACE EDITIONABLE PACKAGE S022498.PSTO1IV0100_CSSCHECKNAMESPACE  AS
 /*--------------------------------------------------------------------*
  *  Declare the PL/SQL Tables used by the Procedures in this Package  *
  *--------------------------------------------------------------------*/
    TYPE t_line     IS TABLE OF SYS.ERROR$.LINE%TYPE
          INDEX BY BINARY_INTEGER;
    TYPE t_position IS TABLE OF SYS.ERROR$.POSITION#%TYPE
          INDEX BY BINARY_INTEGER;
    TYPE t_seqno    IS TABLE OF SYS.ERROR$.SEQUENCE#%TYPE
          INDEX BY BINARY_INTEGER;
    TYPE t_text     IS TABLE OF SYS.ERROR$.TEXT%TYPE
          INDEX BY BINARY_INTEGER;
 
  PROCEDURE PSTV0100_CSSCHECKNAMESPACE
    (RowsToGet           IN INTEGER,
     CreatorName         IN VARCHAR2,
     ObjectName          IN VARCHAR2,
     QualifierName       IN VARCHAR2,
     QualifierCreator    IN VARCHAR2,
     ObjType             IN INTEGER,
     FoundObjType       OUT INTEGER,
     ConflictCreator    OUT VARCHAR2,
     ConflictName       OUT VARCHAR2
    );
 
  PROCEDURE PSTV0100_CSSGETERRMSG
    (RowsToGet           IN INTEGER,
     CreatorName         IN VARCHAR2,
     ObjectName          IN VARCHAR2,
     ObjType             IN INTEGER,
     LineNo             OUT t_line,
     Position           OUT t_position,
     SeqNo              OUT t_seqno,
     ErrMsg             OUT t_text
    );
  END PSTO1IV0100_CSSCHECKNAMESPACE;
/
CREATE OR REPLACE EDITIONABLE PACKAGE S022498.PSTO1IV0100_CSSCID  AS
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
CREATE OR REPLACE EDITIONABLE PACKAGE S022498.PSTO1IV0100_CSSCOLUMN  AS
 /*--------------------------------------------------------------------*
  *  Declare the PL/SQL Tables used by the Procedures in this Package  *
  *--------------------------------------------------------------------*/
    TYPE t_datatype   IS TABLE OF CHAR(9)
          INDEX BY BINARY_INTEGER;
    TYPE t_nullmode IS TABLE OF CHAR(1)
          INDEX BY BINARY_INTEGER;
    TYPE t_columnlength IS TABLE OF INTEGER
          INDEX BY BINARY_INTEGER;
    TYPE t_columnnumber IS TABLE OF INTEGER
          INDEX BY BINARY_INTEGER;
    TYPE t_segcolnumber IS TABLE OF INTEGER
          INDEX BY BINARY_INTEGER;
    TYPE t_defaultvaluelength IS TABLE OF INTEGER
          INDEX BY BINARY_INTEGER;
    TYPE t_numericprecision IS TABLE OF SMALLINT
          INDEX BY BINARY_INTEGER;
    TYPE t_numericscale IS TABLE OF SMALLINT
          INDEX BY BINARY_INTEGER;
    TYPE t_columnname IS TABLE OF SYS.COL$.NAME%TYPE
          INDEX BY BINARY_INTEGER;
    TYPE t_conname IS TABLE OF SYS.CON$.NAME%TYPE
          INDEX BY BINARY_INTEGER;
    TYPE t_prop IS TABLE OF INTEGER
          INDEX BY BINARY_INTEGER;
 
 /*--------------------------------------------------------------------*
  *  Procedure used to acquire Basic Column data from COL$             *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSGETCOLUMN
    (RowsToGet             IN INTEGER,
     ObjectNumIn           IN INTEGER,
     ColLen               OUT t_columnlength,
     ColNum               OUT t_columnnumber,
     DefValLen            OUT t_defaultvaluelength,
     NumPrec              OUT t_numericprecision,
     NumScale             OUT t_numericscale,
     NullMode             OUT t_nullmode,
     DataType             OUT t_datatype,
     ColName              OUT t_columnname,
     CharLen              OUT t_columnlength,
     Properties           OUT t_prop);
 
 /*--------------------------------------------------------------------*
  *  Procedure used to acquire Column default data from COL$           *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0101_CSSEXPCOLUMN
    (RowsToGet             IN INTEGER,
     ObjectNumIn           IN INTEGER,
     OffsetNumIn           IN INTEGER,
     ColumnNumIn           IN INTEGER,
     DefValue             OUT VARCHAR2);
 
 /*--------------------------------------------------------------------*
  *  Procedure used to acquire Cluster Col Ids from COL$, etc..        *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSCLSCOLUMN
    (RowsToGet             IN INTEGER,
     ObjectNumIn           IN INTEGER,
     ClusterNumIn          IN INTEGER,
     ColNum               OUT t_columnnumber,
     SegCol               OUT t_segcolnumber);
 
 /*--------------------------------------------------------------------*
  *  Procedure used to acquire Column NOT Null constraint name         *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSNNMCOLUMN
    (RowsToGet             IN INTEGER,
     ObjectNumIn           IN INTEGER,
     ColNum               OUT t_columnnumber,
     ConName              OUT t_conname);
 
   /*--------------------------------------------------------------------*
    *  Procedure used to acquire XML column schema values                *
    *--------------------------------------------------------------------*/
    PROCEDURE PSTV0100_CSSXMLCOLUMN
      (RowsToGet             IN INTEGER,
       CreatorNameIn         IN VARCHAR2,
       TableNameIn           IN VARCHAR2,
       ColumnNameIn          IN VARCHAR2,
       Schema               OUT VARCHAR2,
       Element              OUT VARCHAR2,
       StorageType          OUT VARCHAR2);
 
  END PSTO1IV0100_CSSCOLUMN;
/
CREATE OR REPLACE EDITIONABLE PACKAGE S022498.PSTO1IV0100_CSSENCRYPT  AS
 
 /*--------------------------------------------------------------------*
  *  Procedure used to acquire Encryption algorithm                    *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSGETENCALG
    (RowsToGet             IN INTEGER,
     ObjectNumIn           IN INTEGER,
     Encalg               OUT INTEGER);
  END PSTO1IV0100_CSSENCRYPT;
/
CREATE OR REPLACE EDITIONABLE PACKAGE S022498.PSTO1IV0100_CSSEXECUTE  AS
 
 /*--------------------------------------------------------------------*
  *  Declare the PL/SQL Tables used by the Procedures in               *
  *  this package                                                      *
  *--------------------------------------------------------------------*/
    TYPE t_creatorname   IS TABLE OF SYS.DBA_USERS.USERNAME%TYPE
          INDEX BY BINARY_INTEGER;
    TYPE t_dbmsint       IS TABLE OF INTEGER
          INDEX BY BINARY_INTEGER;
    TYPE t_objectname    IS TABLE OF SYS.OBJ$.NAME%TYPE
          INDEX BY BINARY_INTEGER;
 
 /*--------------------------------------------------------------------*
  *  Procedure used to acquire dependencies for a Schema name.         *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSGETDEPENDS
    (RowsToGet             IN INTEGER,
     CreatorNum            IN INTEGER,
     CreatorName           IN VARCHAR2,
     ReqCNum              OUT t_dbmsint,
     RefCNum              OUT t_dbmsint,
     ReqOType             OUT t_dbmsint,
     RefOType             OUT t_dbmsint,
     DepMode              OUT t_dbmsint,
     ReqCName             OUT t_creatorname,
     ReqOName             OUT t_objectname,
     RefCName             OUT t_creatorname,
     RefOName             OUT t_objectname);
 
 /*--------------------------------------------------------------------*
  *  Procedure used to acquire synonyms for a Schema name.             *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSGETSYNS
    (RowsToGet             IN INTEGER,
     CreatorNum            IN INTEGER,
     CreatorName           IN VARCHAR2,
     ReqCNum              OUT t_dbmsint,
     RefCNum              OUT t_dbmsint,
     ReqOType             OUT t_dbmsint,
     RefOType             OUT t_dbmsint,
     DepMode              OUT t_dbmsint,
     ReqCName             OUT t_creatorname,
     ReqOName             OUT t_objectname,
     RefCName             OUT t_creatorname,
     RefOName             OUT t_objectname);
 
 /*--------------------------------------------------------------------*
  *  Procedure used to acquire system partition counts                 *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSGETCOUNTS
    (RowsToGet             IN INTEGER,
     ObjectNumIn           IN INTEGER,
     ColNum               OUT INTEGER,
     SegCol               OUT INTEGER);
 
 /*--------------------------------------------------------------------*
  *  Procedure used to acquire system partition names                  *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSGETNAME
    (RowsToGet             IN INTEGER,
     ObjectNumIn           IN INTEGER,
     SpcName              OUT t_objectname);
 
  END PSTO1IV0100_CSSEXECUTE;
/
CREATE OR REPLACE EDITIONABLE PACKAGE S022498.PSTO1IV0100_CSSINDEX  AS
 /*--------------------------------------------------------------------*
  *  Declare the PL/SQL Tables used by the Procedures in this Package  *
  *--------------------------------------------------------------------*/
    TYPE t_creator  IS TABLE OF SYS.DBA_USERS.USERNAME%TYPE
          INDEX BY BINARY_INTEGER;
    TYPE t_idxname  IS TABLE OF SYS.OBJ$.NAME%TYPE
          INDEX BY BINARY_INTEGER;
    TYPE t_conname  IS TABLE OF SYS.CON$.NAME%TYPE
          INDEX BY BINARY_INTEGER;
    TYPE t_subname  IS TABLE OF SYS.OBJ$.SUBNAME%TYPE
          INDEX BY BINARY_INTEGER;
    TYPE t_idxobj   IS TABLE OF SYS.IND$.OBJ#%TYPE
          INDEX BY BINARY_INTEGER;
    TYPE t_colname   IS TABLE OF SYS.COL$.NAME%TYPE
          INDEX BY BINARY_INTEGER;
    TYPE t_tsname       IS TABLE OF SYS.TS$.NAME%TYPE
          INDEX BY BINARY_INTEGER;
    TYPE t_idxcbyte     IS TABLE OF CHAR(1)
          INDEX BY BINARY_INTEGER;
    TYPE t_idxbbyte          IS TABLE OF INTEGER
          INDEX BY BINARY_INTEGER;
    TYPE t_hibound           IS TABLE OF VARCHAR2(1024)
          INDEX BY BINARY_INTEGER;
    TYPE t_idxcdef           IS TABLE OF VARCHAR2(2000)
          INDEX BY BINARY_INTEGER;
    TYPE t_idxflags     IS TABLE OF SYS.IND$.FLAGS%TYPE
          INDEX BY BINARY_INTEGER;
    TYPE t_idxtype     IS TABLE OF SYS.IND$.TYPE#%TYPE
          INDEX BY BINARY_INTEGER;
     TYPE t_idxsegcre   IS TABLE OF VARCHAR2(1024)
          INDEX BY BINARY_INTEGER;
 
 /*--------------------------------------------------------------------*
  *  Procedure used to acquire Indices from USER$,OBJ$,COL$,IND$,ICOL$ *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSGETINDEX
    (RowsToGet             IN INTEGER,
     ObjectNumIn           IN INTEGER,
     IdxCid               OUT t_creator,
     IdxName              OUT t_idxname,
     KeyPos               OUT t_idxbbyte,
     IdxObjId             OUT t_idxobj,
     IdxProp              OUT t_idxbbyte,
     ColProp              OUT t_idxbbyte,
     ColDefLen            OUT t_idxbbyte,
     ColName              OUT t_colname,
     ColDef               OUT t_idxcdef,
     IdxFlags             OUT t_idxflags,
     IdxType              OUT t_idxtype,
     SegCre         OUT t_idxsegcre);
 
 /*--------------------------------------------------------------------*
  *  Procedure used to count BITMAP JOIN Index entries                 *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSGETBMJCNT
    (RowsToGet             IN INTEGER,
     ObjectNumIn           IN INTEGER,
     IdxObjId             OUT t_idxobj,
     RecCnt               OUT t_idxbbyte,
     Type                 OUT t_idxcbyte);
 
 /*--------------------------------------------------------------------*
  *  Procedure used to acquire BITMAP JOIN Index entries               *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSGETBMJIDX
    (RowsToGet             IN INTEGER,
     ObjectNumIn           IN INTEGER,
     IdxCid               OUT t_creator,
     IdxName              OUT t_idxname,
     JtblCid              OUT t_creator,
     JtblName             OUT t_idxname,
     IdxObjId             OUT t_idxobj,
     KeyPos               OUT t_idxbbyte,
     ColProp              OUT t_idxbbyte,
     ColName              OUT t_colname);
 
 /*--------------------------------------------------------------------*
  *  Procedure used to acquire BITMAP JOIN Predicates                  *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSGETBMJCOL
    (RowsToGet             IN INTEGER,
     ObjectNumIn           IN INTEGER,
     Tbl1Cid              OUT t_creator,
     Tbl1Name             OUT t_idxname,
     Tbl1Col              OUT t_colname,
     Tbl2Cid              OUT t_creator,
     Tbl2Name             OUT t_idxname,
     Tbl2Col              OUT t_colname,
     JoinOper             OUT t_idxbbyte,
     Tbl1Inst             OUT t_idxbbyte,
     Tbl2Inst             OUT t_idxbbyte);
 
 /*--------------------------------------------------------------------*
  *  Procedure to acquire UnqRel Index data                            *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSGETUNQREL
    (RowsToGet             IN INTEGER,
     ObjectNumIn           IN INTEGER,
     ConName              OUT t_conname,
     ConId                OUT t_idxbbyte,
     Enabled              OUT t_idxbbyte,
     ColName              OUT t_colname,
     KeyPos               OUT t_idxbbyte,
     Deferable            OUT t_idxcbyte,
     DeferInit            OUT t_idxcbyte,
     Validated            OUT t_idxcbyte,
     SegCre         OUT t_idxsegcre);
 
 /*--------------------------------------------------------------------*
  *  Procedure used to acquire DDL Object data                         *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSDDLINDEX
    (RowsToGet             IN INTEGER,
     ObjectNumIn           IN INTEGER,
     PctgFree             OUT INTEGER,
     InitTran             OUT INTEGER,
     MaxTran              OUT INTEGER,
     InitExt              OUT INTEGER,
     NextExt              OUT INTEGER,
     MinExt               OUT INTEGER,
     MaxExt               OUT INTEGER,
     PctIncr              OUT INTEGER,
     Lists                OUT INTEGER,
     Groups               OUT INTEGER,
     TsBlkSize            OUT INTEGER,
     ParaDegree           OUT INTEGER,
     ParaInst             OUT INTEGER,
     CompCols             OUT INTEGER,
     LogFlag              OUT CHAR,
     PartFlag             OUT CHAR,
     Type                 OUT CHAR,
     BPool                OUT CHAR,
     RevFlag              OUT CHAR,
     TSName               OUT VARCHAR2,
     SegCre         OUT VARCHAR2);
 
 /*--------------------------------------------------------------------*
  *  Procedure used to acquire DDL Index PartBase                      *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSDDLIDXPARTBASE
    (RowsToGet             IN INTEGER,
     ObjectNumIn           IN INTEGER,
     PartCnt              OUT INTEGER,
     PartKeyCnt           OUT INTEGER,
     PctgFree             OUT INTEGER,
     InitTran             OUT INTEGER,
     MaxTran              OUT INTEGER,
     InitExt              OUT INTEGER,
     NextExt              OUT INTEGER,
     MinExt               OUT INTEGER,
     MaxExt               OUT INTEGER,
     PctIncr              OUT INTEGER,
     Lists                OUT INTEGER,
     TsBlkSize            OUT INTEGER,
     PartType             OUT INTEGER,
     SubPartType          OUT INTEGER,
     SubPartKeyCols       OUT INTEGER,
     DefSubPartCnt        OUT INTEGER,
     PartLoc              OUT CHAR,
     PartAlign            OUT CHAR,
     LogFlag              OUT CHAR,
     BPool                OUT CHAR,
     TSName               OUT VARCHAR2);
 
 /*--------------------------------------------------------------------*
  *  Procedure used to acquire DDL Index PartKeys                      *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSDDLIDXPARTKEYS
    (RowsToGet             IN INTEGER,
     ObjectNumIn           IN INTEGER,
     KeyNum               OUT t_idxbbyte,
     KeyPos               OUT t_idxbbyte);
 
 /*--------------------------------------------------------------------*
  *  Procedure used to acquire DDL Index Partitions                    *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSDDLIDXPARTSLOT
    (RowsToGet             IN INTEGER,
     ObjectNumIn           IN INTEGER,
     PartObjNum           OUT t_idxbbyte,
     PartNum              OUT t_idxbbyte,
     PctgFree             OUT t_idxbbyte,
     InitTran             OUT t_idxbbyte,
     MaxTran              OUT t_idxbbyte,
     InitExt              OUT t_idxbbyte,
     NextExt              OUT t_idxbbyte,
     MinExt               OUT t_idxbbyte,
     MaxExt               OUT t_idxbbyte,
     PctIncr              OUT t_idxbbyte,
     Lists                OUT t_idxbbyte,
     TsBlkSize            OUT t_idxbbyte,
     HiBndLen             OUT t_idxbbyte,
     LogFlag              OUT t_idxcbyte,
     BPool                OUT t_idxcbyte,
     PartComp             OUT t_idxcbyte,
     PartName             OUT t_subname,
     TSName               OUT t_tsname,
     HiBndVal             OUT t_hibound);
 
 /*--------------------------------------------------------------------*
  *  Procedure used to acquire COMPOSITE Index Part                    *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSDDLIDXCOMPARTSLOT
    (RowsToGet             IN INTEGER,
     ObjectNumIn           IN INTEGER,
     PartObjNum           OUT t_idxbbyte,
     PartNum              OUT t_idxbbyte,
     PctgFree             OUT t_idxbbyte,
     InitTran             OUT t_idxbbyte,
     MaxTran              OUT t_idxbbyte,
     InitExt              OUT t_idxbbyte,
     NextExt              OUT t_idxbbyte,
     MinExt               OUT t_idxbbyte,
     MaxExt               OUT t_idxbbyte,
     PctIncr              OUT t_idxbbyte,
     Lists                OUT t_idxbbyte,
     TsBlkSize            OUT t_idxbbyte,
     HiBndLen             OUT t_idxbbyte,
     LogFlag              OUT t_idxcbyte,
     BPool                OUT t_idxcbyte,
     PartComp             OUT t_idxcbyte,
     PartName             OUT t_subname,
     TSName               OUT t_tsname,
     HiBndVal             OUT t_hibound,
     SubPartCnt           OUT t_idxbbyte);
 
 /*--------------------------------------------------------------------*
  *  Procedure used to acquire Index SubPartitions                     *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSDDLIDXSUBPARTSLOT
    (RowsToGet             IN INTEGER,
     ObjectNumIn           IN INTEGER,
     SubPartObjNum        OUT t_idxbbyte,
     SubPartNum           OUT t_idxbbyte,
     PctgFree             OUT t_idxbbyte,
     InitTran             OUT t_idxbbyte,
     MaxTran              OUT t_idxbbyte,
     InitExt              OUT t_idxbbyte,
     NextExt              OUT t_idxbbyte,
     MinExt               OUT t_idxbbyte,
     MaxExt               OUT t_idxbbyte,
     PctIncr              OUT t_idxbbyte,
     Lists                OUT t_idxbbyte,
     Groups               OUT t_idxbbyte,
     TsBlkSize            OUT t_idxbbyte,
     LogFlag              OUT t_idxcbyte,
     BPool                OUT t_idxcbyte,
     PartName             OUT t_subname,
     TSName               OUT t_tsname);
 
 /*--------------------------------------------------------------------*
  *  Procedure for DBMS Index List                                     *
  *  Include both System and Primary Key Indexes                       *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSINDEXLIST0
    (RowsToGet             IN INTEGER,
     IdxCid               OUT t_creator,
     IdxTable             OUT t_idxname,
     IdxDef               OUT t_creator,
     IdxName              OUT t_idxname,
     IdxProp              OUT t_idxbbyte,
     ColProp              OUT t_idxbbyte,
     ColName              OUT t_colname,
     ColCnt               OUT t_idxbbyte,
     KeyPos               OUT t_idxbbyte,
     PKFlag               OUT t_idxbbyte,
     SegCre               OUT t_idxsegcre);
 
 /*--------------------------------------------------------------------*
  *  Procedure for DBMS Index List                                     *
  *  Exclude System Tables                                             *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSINDEXLIST1
    (RowsToGet             IN INTEGER,
     IdxCid               OUT t_creator,
     IdxTable             OUT t_idxname,
     IdxDef               OUT t_creator,
     IdxName              OUT t_idxname,
     IdxProp              OUT t_idxbbyte,
     ColProp              OUT t_idxbbyte,
     ColName              OUT t_colname,
     ColCnt               OUT t_idxbbyte,
     KeyPos               OUT t_idxbbyte,
     PKFlag               OUT t_idxbbyte,
     SegCre               OUT t_idxsegcre);
 
 /*--------------------------------------------------------------------*
  *  Procedure for DBMS Index List                                     *
  *  Exclude Tables with Primary Keys                                  *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSINDEXLIST2
    (RowsToGet             IN INTEGER,
     IdxCid               OUT t_creator,
     IdxTable             OUT t_idxname,
     IdxDef               OUT t_creator,
     IdxName              OUT t_idxname,
     IdxProp              OUT t_idxbbyte,
     ColProp              OUT t_idxbbyte,
     ColName              OUT t_colname,
     ColCnt               OUT t_idxbbyte,
     KeyPos               OUT t_idxbbyte,
     PKFlag               OUT t_idxbbyte,
     SegCre               OUT t_idxsegcre);
 
 /*--------------------------------------------------------------------*
  *  Procedure for DBMS Index List                                     *
  *  Exclude System Tables and Tables with Primary Keys                *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSINDEXLIST3
    (RowsToGet             IN INTEGER,
     IdxCid               OUT t_creator,
     IdxTable             OUT t_idxname,
     IdxDef               OUT t_creator,
     IdxName              OUT t_idxname,
     IdxProp              OUT t_idxbbyte,
     ColProp              OUT t_idxbbyte,
     ColName              OUT t_colname,
     ColCnt               OUT t_idxbbyte,
     KeyPos               OUT t_idxbbyte,
     PKFlag               OUT t_idxbbyte,
     SegCre               OUT t_idxsegcre);
 
   /*--------------------------------------------------------------------*
    *  Procedure used to acquire XML Index Parameter values                *
    *--------------------------------------------------------------------*/
    PROCEDURE PSTV0100_CSSXMLINDEX
      (RowsToGet             IN INTEGER,
       CreatorNameIn         IN VARCHAR2,
       TableNameIn           IN VARCHAR2,
       IdxNameIn             IN VARCHAR2,
       Paths                OUT VARCHAR2,
       NSMap                OUT VARCHAR2,
       Async                OUT VARCHAR2,
       JobName              OUT VARCHAR2,
       Interval             OUT VARCHAR2,
       ExclIncl             OUT VARCHAR2,
       PathTblObjNum        OUT INTEGER,
       PathTblName          OUT VARCHAR2,
       PathIdxObjNum        OUT INTEGER,
       PathIdxName          OUT VARCHAR2,
       ValueIdxObjNum       OUT INTEGER,
       ValueIdxName         OUT VARCHAR2,
       OrderIdxObjNum       OUT INTEGER,
       OrderIdxName         OUT VARCHAR2);
 
 
 
  END PSTO1IV0100_CSSINDEX;
/
CREATE OR REPLACE EDITIONABLE PACKAGE S022498.PSTO1IV0100_CSSPKDEF  AS
 /*--------------------------------------------------------------------*
  *  Declare the PL/SQL Tables used by the Procedures in this Package  *
  *--------------------------------------------------------------------*/
    TYPE t_colnametype   IS TABLE OF SYS.COL$.NAME%TYPE
          INDEX BY BINARY_INTEGER;
    TYPE t_keypostype        IS TABLE OF INTEGER
          INDEX BY BINARY_INTEGER;
    TYPE t_pknametype    IS TABLE OF SYS.CON$.NAME%TYPE
          INDEX BY BINARY_INTEGER;
    TYPE t_pkobjtype   IS TABLE OF SYS.CDEF$.CON#%TYPE
          INDEX BY BINARY_INTEGER;
    TYPE t_pkidxobjtype IS TABLE OF SYS.CDEF$.ENABLED%TYPE
          INDEX BY BINARY_INTEGER;
    TYPE t_creatorname   IS TABLE OF SYS.DBA_USERS.USERNAME%TYPE
          INDEX BY BINARY_INTEGER;
    TYPE t_tablename     IS TABLE OF SYS.OBJ$.NAME%TYPE
          INDEX BY BINARY_INTEGER;
    TYPE t_deferflag  IS TABLE OF CHAR(1)
          INDEX BY BINARY_INTEGER;
    TYPE t_idxsegcre   IS TABLE OF VARCHAR2(1024)
          INDEX BY BINARY_INTEGER;
 
 /*--------------------------------------------------------------------*
  *  Procedure used to acquire Primary Key Data from COL$ and CCOL$    *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSGETPKDEF
    (RowsToGet             IN INTEGER,
     ObjectNumIn           IN INTEGER,
     PkDName              OUT t_pknametype,
     PkDObjId             OUT t_pkobjtype,
     PkDIdxObjId          OUT t_pkidxobjtype,
     ColName              OUT t_colnametype,
     KeyPos               OUT t_keypostype,
     Deferable            OUT t_deferflag,
     DeferInit            OUT t_deferflag,
     Validated            OUT t_deferflag,
     SegCre				 OUT t_idxsegcre);
 
 /*--------------------------------------------------------------------*
  *  Procedure used to acquire PK List from Creator/Table patterns     *
  *  when both names are explicit values                               *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSGETPKDLIST0
    (RowsToGet             IN INTEGER,
     CidPatternIn          IN VARCHAR2,
     TblPatternIn          IN VARCHAR2,
     CreatorName          OUT t_creatorname,
     TableName            OUT t_tablename);
 
 /*--------------------------------------------------------------------*
  *  Procedure used to acquire PK List from Creator/Table patterns     *
  *  when Creator is a LIKE value and Table is explicit                *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSGETPKDLIST1
    (RowsToGet             IN INTEGER,
     CidPatternIn          IN VARCHAR2,
     TblPatternIn          IN VARCHAR2,
     CreatorName          OUT t_creatorname,
     TableName            OUT t_tablename);
 
 /*--------------------------------------------------------------------*
  *  Procedure used to acquire PK List from Creator/Table patterns     *
  *  when Creator is explicit and Table is a LIKE value                *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSGETPKDLIST2
    (RowsToGet             IN INTEGER,
     CidPatternIn          IN VARCHAR2,
     TblPatternIn          IN VARCHAR2,
     CreatorName          OUT t_creatorname,
     TableName            OUT t_tablename);
 
 /*--------------------------------------------------------------------*
  *  Procedure used to acquire PK List from Creator/Table patterns     *
  *  when both names are LIKE values                                   *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSGETPKDLIST3
    (RowsToGet             IN INTEGER,
     CidPatternIn          IN VARCHAR2,
     TblPatternIn          IN VARCHAR2,
     CreatorName          OUT t_creatorname,
     TableName            OUT t_tablename);
  END PSTO1IV0100_CSSPKDEF;
/
CREATE OR REPLACE EDITIONABLE PACKAGE S022498.PSTO1IV0100_CSSRELCON  AS
 /*--------------------------------------------------------------------*
  *  Declare the PL/SQL Tables used by the Procedures in this Package  *
  *--------------------------------------------------------------------*/
    TYPE t_depcid     IS TABLE OF SYS.DBA_USERS.USERNAME%TYPE
          INDEX BY BINARY_INTEGER;
    TYPE t_deptbl      IS TABLE OF SYS.OBJ$.NAME%TYPE
          INDEX BY BINARY_INTEGER;
    TYPE t_relname       IS TABLE OF SYS.CON$.NAME%TYPE
          INDEX BY BINARY_INTEGER;
    TYPE t_parcid     IS TABLE OF SYS.DBA_USERS.USERNAME%TYPE
          INDEX BY BINARY_INTEGER;
    TYPE t_partbl      IS TABLE OF SYS.OBJ$.NAME%TYPE
          INDEX BY BINARY_INTEGER;
    TYPE t_depcidid      IS TABLE OF SYS.OBJ$.OWNER#%TYPE
          INDEX BY BINARY_INTEGER;
    TYPE t_parcidid      IS TABLE OF SYS.OBJ$.OWNER#%TYPE
          INDEX BY BINARY_INTEGER;
    TYPE t_depconid      IS TABLE OF SYS.CDEF$.CON#%TYPE
          INDEX BY BINARY_INTEGER;
    TYPE t_parconid      IS TABLE OF SYS.CDEF$.RCON#%TYPE
          INDEX BY BINARY_INTEGER;
    TYPE t_enableid      IS TABLE OF SYS.CDEF$.ENABLED%TYPE
          INDEX BY BINARY_INTEGER;
    TYPE t_deferflag     IS TABLE OF CHAR(1)
          INDEX BY BINARY_INTEGER;
    TYPE t_deleterule    IS TABLE OF SYS.CDEF$.REFACT%TYPE
          INDEX BY BINARY_INTEGER;
    TYPE t_conid         IS TABLE OF SYS.CCOL$.CON#%TYPE
          INDEX BY BINARY_INTEGER;
    TYPE t_colid         IS TABLE OF SYS.CCOL$.COL#%TYPE
          INDEX BY BINARY_INTEGER;
    TYPE t_colpos        IS TABLE OF SYS.CCOL$.POS#%TYPE
          INDEX BY BINARY_INTEGER;
 
 /*--------------------------------------------------------------------*
  *  Procedure used to acquire RelLinks for a Creator Id.              *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSGETRELLINK
    (RowsToGet             IN INTEGER,
     CreatorNumIn          IN INTEGER,
     CreatorNameIn         IN VARCHAR2,
     DepCidName           OUT t_depcid,
     DepTblName           OUT t_deptbl,
     RelName              OUT t_relname,
     ParCidName           OUT t_parcid,
     ParTblName           OUT t_partbl,
     DepCidId             OUT t_depcidid,
     ParCidId             OUT t_parcidid,
     DepConId             OUT t_depconid,
     ParConId             OUT t_parconid,
     EnableId             OUT t_enableid,
     Deferable            OUT t_deferflag,
     DeferInit            OUT t_deferflag,
     Validated            OUT t_deferflag,
     DeleteRule           OUT t_deleterule);
 
 /*--------------------------------------------------------------------*
  *  Procedure used to acquire Constraint details from CCOL$           *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSGETCONDETAIL
    (RowsToGet             IN INTEGER,
     ParConId              IN INTEGER,
     DepConId              IN INTEGER,
     ConId                OUT t_conid,
     ColId                OUT t_colid,
     ColPos               OUT t_colpos);
 
 /*--------------------------------------------------------------------*
  *  Procedure used to acquire FK List from Creator/Table/RelName      *
  *  patterns when all names are explicit values                       *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSGETRELLIST0
    (RowsToGet             IN INTEGER,
     CidPatternIn          IN VARCHAR2,
     TblPatternIn          IN VARCHAR2,
     RelPatternIn          IN VARCHAR2,
     DepCidName           OUT t_depcid,
     DepTblName           OUT t_deptbl,
     RelName              OUT t_relname,
     ParCidName           OUT t_parcid,
     ParTblName           OUT t_partbl);
 
 /*--------------------------------------------------------------------*
  *  Procedure used to acquire Table List from Creator/Table/RelName   *
  *  patterns when Creator is a LIKE value and others explicit         *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSGETRELLIST1
    (RowsToGet             IN INTEGER,
     CidPatternIn          IN VARCHAR2,
     TblPatternIn          IN VARCHAR2,
     RelPatternIn          IN VARCHAR2,
     DepCidName           OUT t_depcid,
     DepTblName           OUT t_deptbl,
     RelName              OUT t_relname,
     ParCidName           OUT t_parcid,
     ParTblName           OUT t_partbl);
 
 /*--------------------------------------------------------------------*
  *  Procedure used to acquire Table List from Creator/Table/RelName   *
  *  patterns when Table is a LIKE value and others explicit           *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSGETRELLIST2
    (RowsToGet             IN INTEGER,
     CidPatternIn          IN VARCHAR2,
     TblPatternIn          IN VARCHAR2,
     RelPatternIn          IN VARCHAR2,
     DepCidName           OUT t_depcid,
     DepTblName           OUT t_deptbl,
     RelName              OUT t_relname,
     ParCidName           OUT t_parcid,
     ParTblName           OUT t_partbl);
 
 /*--------------------------------------------------------------------*
  *  Procedure used to acquire Table List from Creator/Table/RelName   *
  *  patterns when Creator and Table values are LIKE values            *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSGETRELLIST3
    (RowsToGet             IN INTEGER,
     CidPatternIn          IN VARCHAR2,
     TblPatternIn          IN VARCHAR2,
     RelPatternIn          IN VARCHAR2,
     DepCidName           OUT t_depcid,
     DepTblName           OUT t_deptbl,
     RelName              OUT t_relname,
     ParCidName           OUT t_parcid,
     ParTblName           OUT t_partbl);
 
 /*--------------------------------------------------------------------*
  *  Procedure used to acquire Table List from Creator/Table/RelName   *
  *  patterns when RelName is a LIKE value                             *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSGETRELLIST4
    (RowsToGet             IN INTEGER,
     CidPatternIn          IN VARCHAR2,
     TblPatternIn          IN VARCHAR2,
     RelPatternIn          IN VARCHAR2,
     DepCidName           OUT t_depcid,
     DepTblName           OUT t_deptbl,
     RelName              OUT t_relname,
     ParCidName           OUT t_parcid,
     ParTblName           OUT t_partbl);
 
 /*--------------------------------------------------------------------*
  *  Procedure used to acquire Table List from Creator/Table/RelName   *
  *  patterns when Creator and RelName are LIKE values                 *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSGETRELLIST5
    (RowsToGet             IN INTEGER,
     CidPatternIn          IN VARCHAR2,
     TblPatternIn          IN VARCHAR2,
     RelPatternIn          IN VARCHAR2,
     DepCidName           OUT t_depcid,
     DepTblName           OUT t_deptbl,
     RelName              OUT t_relname,
     ParCidName           OUT t_parcid,
     ParTblName           OUT t_partbl);
 
 /*--------------------------------------------------------------------*
  *  Procedure used to acquire Table List from Creator/Table/RelName   *
  *  patterns when Table and RelName are LIKE values                   *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSGETRELLIST6
    (RowsToGet             IN INTEGER,
     CidPatternIn          IN VARCHAR2,
     TblPatternIn          IN VARCHAR2,
     RelPatternIn          IN VARCHAR2,
     DepCidName           OUT t_depcid,
     DepTblName           OUT t_deptbl,
     RelName              OUT t_relname,
     ParCidName           OUT t_parcid,
     ParTblName           OUT t_partbl);
 
 /*--------------------------------------------------------------------*
  *  Procedure used to acquire Table List from Creator/Table/RelName   *
  *  patterns when all names are LIKE values                           *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSGETRELLIST7
    (RowsToGet             IN INTEGER,
     CidPatternIn          IN VARCHAR2,
     TblPatternIn          IN VARCHAR2,
     RelPatternIn          IN VARCHAR2,
     DepCidName           OUT t_depcid,
     DepTblName           OUT t_deptbl,
     RelName              OUT t_relname,
     ParCidName           OUT t_parcid,
     ParTblName           OUT t_partbl);
  END PSTO1IV0100_CSSRELCON;
/
CREATE OR REPLACE EDITIONABLE PACKAGE S022498.PSTO1IV0100_CSSSEQUENCE  AS
 /*--------------------------------------------------------------------*
  *  Declare the PL/SQL Tables used by the Procedures in this Package  *
  *--------------------------------------------------------------------*/
    TYPE t_creatorname   IS TABLE OF SYS.DBA_USERS.USERNAME%TYPE
          INDEX BY BINARY_INTEGER;
    TYPE t_sequencename  IS TABLE OF SYS.OBJ$.NAME%TYPE
          INDEX BY BINARY_INTEGER;
    TYPE t_integer       IS TABLE OF INTEGER
          INDEX BY BINARY_INTEGER;
    TYPE t_varchar2      IS TABLE OF VARCHAR2(30)
          INDEX BY BINARY_INTEGER;
    TYPE t_bool          IS TABLE OF CHAR(1)
          INDEX BY BINARY_INTEGER;
 
 /*--------------------------------------------------------------------*
  *  Procedure used to acquire Sequence Attributes                     *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSGETSEQDATA
    (RowsToGet             IN INTEGER,
     CidName               IN VARCHAR2,
     SeqName               IN VARCHAR2,
     ObjNum               OUT INTEGER,
     CidNum               OUT INTEGER,
     Cache                OUT INTEGER,
     Incr                 OUT VARCHAR2,
     MinValue             OUT VARCHAR2,
     MaxValue             OUT VARCHAR2,
     Cycle                OUT CHAR,
     Ordering             OUT CHAR,
     NoMin                OUT CHAR,
     NoMax                OUT CHAR,
     Owner                OUT VARCHAR2,
     Name                 OUT VARCHAR2);
 
 /*--------------------------------------------------------------------*
  *  Procedure used to acquire Sequence List from Creator/Sequence     *
  *  patterns when both names are explicit values                      *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSGETSEQLIST0
    (RowsToGet             IN INTEGER,
     CidPatternIn          IN VARCHAR2,
     SeqPatternIn          IN VARCHAR2,
     Increment            OUT t_varchar2,
     MinValue             OUT t_varchar2,
     MaxValue             OUT t_varchar2,
     Cycle                OUT t_bool,
     Ordering             OUT t_bool,
     Cache                OUT t_integer,
     CreatorName          OUT t_creatorname,
     SequenceName         OUT t_sequencename);
 
 /*--------------------------------------------------------------------*
  *  Procedure used to acquire Sequence List from Creator/Sequence     *
  *  when Creator is a LIKE value and Sequence is explicit             *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSGETSEQLIST1
    (RowsToGet             IN INTEGER,
     CidPatternIn          IN VARCHAR2,
     SeqPatternIn          IN VARCHAR2,
     Increment            OUT t_varchar2,
     MinValue             OUT t_varchar2,
     MaxValue             OUT t_varchar2,
     Cycle                OUT t_bool,
     Ordering             OUT t_bool,
     Cache                OUT t_integer,
     CreatorName          OUT t_creatorname,
     SequenceName         OUT t_sequencename);
 
 /*--------------------------------------------------------------------*
  *  Procedure used to acquire Sequence List from Creator/Sequence     *
  *  when Creator is explicit and Sequence is a LIKE value             *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSGETSEQLIST2
    (RowsToGet             IN INTEGER,
     CidPatternIn          IN VARCHAR2,
     SeqPatternIn          IN VARCHAR2,
     Increment            OUT t_varchar2,
     MinValue             OUT t_varchar2,
     MaxValue             OUT t_varchar2,
     Cycle                OUT t_bool,
     Ordering             OUT t_bool,
     Cache                OUT t_integer,
     CreatorName          OUT t_creatorname,
     SequenceName         OUT t_sequencename);
 
 /*--------------------------------------------------------------------*
  *  Procedure used to acquire Sequence List from Creator/Sequence     *
  *  when both names are LIKE values                                   *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSGETSEQLIST3
    (RowsToGet             IN INTEGER,
     CidPatternIn          IN VARCHAR2,
     SeqPatternIn          IN VARCHAR2,
     Increment            OUT t_varchar2,
     MinValue             OUT t_varchar2,
     MaxValue             OUT t_varchar2,
     Cycle                OUT t_bool,
     Ordering             OUT t_bool,
     Cache                OUT t_integer,
     CreatorName          OUT t_creatorname,
     SequenceName         OUT t_sequencename);
  END PSTO1IV0100_CSSSEQUENCE;
/
CREATE OR REPLACE EDITIONABLE PACKAGE S022498.PSTO1IV0100_CSSSPCMGT  AS
 /*--------------------------------------------------------------------*
  *  Declare the PL/SQL Tables used by the Procedures in this Package  *
  *--------------------------------------------------------------------*/
    TYPE t_spcnametype   IS TABLE OF SYS.TS$.NAME%TYPE
          INDEX BY BINARY_INTEGER;
 
 /*--------------------------------------------------------------------*
  *  Procedure used to acquire Tablespace Data from TS$                *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSGETTBLSPC
    (RowsToGet             IN INTEGER,
     SpcNameIn             IN VARCHAR2,
     SpcObjId             OUT INTEGER);
 
 /*--------------------------------------------------------------------*
  *  Procedure used to acquire PK List from Creator/Table patterns     *
  *  when both names are explicit values                               *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSGETSPCLIST
    (RowsToGet             IN INTEGER,
     SpcName              OUT t_spcnametype);
 
 /*--------------------------------------------------------------------*
  *  Procedure used to acquire Database Signature Token                *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSGETSIGNATURE
    (RowsToGet             IN INTEGER,
     SignToken            OUT VARCHAR2);
  END PSTO1IV0100_CSSSPCMGT;
/
CREATE OR REPLACE EDITIONABLE PACKAGE S022498.PSTO1IV0100_CSSSYNONYM  AS
 /*--------------------------------------------------------------------*
  *  Declare the PL/SQL Tables used by the Procedures in this Package  *
  *--------------------------------------------------------------------*/
    TYPE t_ownername     IS TABLE OF SYS.DBA_USERS.USERNAME%TYPE
          INDEX BY BINARY_INTEGER;
    TYPE t_objectname       IS TABLE OF SYS.OBJ$.NAME%TYPE
          INDEX BY BINARY_INTEGER;
    TYPE t_integer       IS TABLE OF INTEGER
          INDEX BY BINARY_INTEGER;
    TYPE t_char          IS TABLE OF CHAR(1)
          INDEX BY BINARY_INTEGER;
    TYPE t_proctext      IS TABLE OF VARCHAR2(254)
          INDEX BY BINARY_INTEGER;
 
 /*--------------------------------------------------------------------*
  *  Procedure used to get Extended Data for a specific Procedure      *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSGETSYNDATA
    (RowsToGet             IN INTEGER,
     CidName               IN VARCHAR2,
     SynName               IN VARCHAR2,
     ObjectNum            OUT INTEGER,
     CidNum               OUT INTEGER,
     RefNum               OUT INTEGER,
     RefType              OUT INTEGER,
     OPublic              OUT CHAR,
     Owner                OUT VARCHAR2,
     SynmName             OUT VARCHAR2,
     RefOwner             OUT VARCHAR2,
     RefName              OUT VARCHAR2,
     RefLink              OUT VARCHAR2);
 
 /*--------------------------------------------------------------------*
  *  Procedure used to get Synonym List for explicit CID and Procs     *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSGETSYNLIST0
    (RowsToGet             IN INTEGER,
     CidPattern            IN VARCHAR2,
     SynPattern            IN VARCHAR2,
     OPublic              OUT t_char,
     ORemote              OUT t_char,
     CidName              OUT t_ownername,
     SynName              OUT t_objectname,
     RefOwner             OUT t_ownername,
     RefName              OUT t_objectname);
 
 /*--------------------------------------------------------------------*
  *  Get Procedure List for wildcard CID and explicit Synonym Name     *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSGETSYNLIST1
    (RowsToGet             IN INTEGER,
     CidPattern            IN VARCHAR2,
     SynPattern            IN VARCHAR2,
     OPublic              OUT t_char,
     ORemote              OUT t_char,
     CidName              OUT t_ownername,
     SynName              OUT t_objectname,
     RefOwner             OUT t_ownername,
     RefName              OUT t_objectname);
 
 /*--------------------------------------------------------------------*
  *  Get Procedure List for explicit CID and wildcard Synonym name     *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSGETSYNLIST2
    (RowsToGet             IN INTEGER,
     CidPattern            IN VARCHAR2,
     SynPattern            IN VARCHAR2,
     OPublic              OUT t_char,
     ORemote              OUT t_char,
     CidName              OUT t_ownername,
     SynName              OUT t_objectname,
     RefOwner             OUT t_ownername,
     RefName              OUT t_objectname);
 
 /*--------------------------------------------------------------------*
  *  Get Procedure List for wildcard CID and Synonym names             *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSGETSYNLIST3
    (RowsToGet             IN INTEGER,
     CidPattern            IN VARCHAR2,
     SynPattern            IN VARCHAR2,
     OPublic              OUT t_char,
     ORemote              OUT t_char,
     CidName              OUT t_ownername,
     SynName              OUT t_objectname,
     RefOwner             OUT t_ownername,
     RefName              OUT t_objectname);
  END PSTO1IV0100_CSSSYNONYM;
/
CREATE OR REPLACE EDITIONABLE PACKAGE S022498.PSTO1IV0100_CSSTABLE  AS
 /*--------------------------------------------------------------------*
  *  Declare the PL/SQL Tables used by the Procedures in this Package  *
  *--------------------------------------------------------------------*/
    TYPE t_creatorname   IS TABLE OF SYS.DBA_USERS.USERNAME%TYPE
          INDEX BY BINARY_INTEGER;
    TYPE t_tablename     IS TABLE OF SYS.OBJ$.NAME%TYPE
          INDEX BY BINARY_INTEGER;
    TYPE t_tblcbyte     IS TABLE OF CHAR(1)
          INDEX BY BINARY_INTEGER;
    TYPE t_tblbbyte          IS TABLE OF INTEGER
          INDEX BY BINARY_INTEGER;
    TYPE t_subname  IS TABLE OF SYS.OBJ$.SUBNAME%TYPE
          INDEX BY BINARY_INTEGER;
    TYPE t_tsname       IS TABLE OF SYS.TS$.NAME%TYPE
          INDEX BY BINARY_INTEGER;
    TYPE t_hibound           IS TABLE OF VARCHAR2(1024)
          INDEX BY BINARY_INTEGER;
    TYPE t_colname           IS TABLE OF VARCHAR2(4000)
       INDEX BY BINARY_INTEGER;
    TYPE t_segcre           IS TABLE OF VARCHAR2(1024)
       INDEX BY BINARY_INTEGER;
 
 /*--------------------------------------------------------------------*
  *  Procedure used to acquire Basic Object data from OBJ$             *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSGETOBJECT
    (RowsToGet             IN INTEGER,
     CreatorNumIn          IN INTEGER,
     CreatorNameIn         IN VARCHAR2,
     ObjectNameIn          IN VARCHAR2,
     ObjectType           OUT CHAR,
     ObjectStatus         OUT CHAR,
     RemoteType           OUT CHAR,
     SynonymType          OUT CHAR,
     CreatorNumId         OUT INTEGER,
     ObjectNumId          OUT INTEGER,
     TblProp              OUT INTEGER,
     RemoteCreator        OUT VARCHAR2,
     RemoteObject         OUT VARCHAR2,
     RemoteLink           OUT VARCHAR2,
     ReadOnlyT             OUT CHAR);
 
 /*--------------------------------------------------------------------*
  *  Procedure used to acquire Extended Object data from TAB$, TS$     *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSEXPOBJECT
    (RowsToGet             IN INTEGER,
     ObjectNumIn           IN INTEGER,
     RowCount             OUT INTEGER,
     ColCount             OUT INTEGER,
     InsTrigCnt           OUT INTEGER,
     UpdTrigCnt           OUT INTEGER,
     DelTrigCnt           OUT INTEGER);
 
 /*--------------------------------------------------------------------*
  *  Procedure used to acquire DDL Object data from TAB$,TS$,SEG$      *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSDDLOBJECT
    (RowsToGet             IN INTEGER,
     ObjectNumIn           IN INTEGER,
     PctgFree             OUT INTEGER,
     PctUsed              OUT INTEGER,
     InitTran             OUT INTEGER,
     MaxTran              OUT INTEGER,
     InitExt              OUT INTEGER,
     NextExt              OUT INTEGER,
     MinExt               OUT INTEGER,
     MaxExt               OUT INTEGER,
     PctIncr              OUT INTEGER,
     Lists                OUT INTEGER,
     Groups               OUT INTEGER,
     TsBlkSize            OUT INTEGER,
     Parallel             OUT INTEGER,
     Instances            OUT INTEGER,
     CacheStat            OUT INTEGER,
     ClsObjId             OUT INTEGER,
     SpcObjId             OUT INTEGER,
     TblFlag              OUT INTEGER,
     ObjFlag              OUT INTEGER,
     ChkCount             OUT INTEGER,
     Spare1               OUT INTEGER,
     TableSpaceName       OUT VARCHAR2,
     ClsIotName           OUT VARCHAR2,
     SegmentCre			 OUT VARCHAR2,
     TblProperty			 OUT VARCHAR2,
     FlashbackStr         OUT VARCHAR2);
 
 /*--------------------------------------------------------------------*
  *  Procedure used to acquire DDL Table PartBase from PARTOBJ$,TS$    *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSDDLTBLPARTBASE
    (RowsToGet             IN INTEGER,
     ObjectNumIn           IN INTEGER,
     PartCnt              OUT INTEGER,
     PartKeyCnt           OUT INTEGER,
     PartType             OUT INTEGER,
     PctgFree             OUT INTEGER,
     PctgUsed             OUT INTEGER,
     InitTran             OUT INTEGER,
     MaxTran              OUT INTEGER,
     InitExt              OUT INTEGER,
     NextExt              OUT INTEGER,
     MinExt               OUT INTEGER,
     MaxExt               OUT INTEGER,
     PctIncr              OUT INTEGER,
     Lists                OUT INTEGER,
     Groups               OUT INTEGER,
     TsBlkSize            OUT INTEGER,
     LogFlag              OUT CHAR,
     BPool                OUT CHAR,
     TSName               OUT VARCHAR2,
     Spare2               OUT VARCHAR2,
     IntervalStr          OUT VARCHAR2,
     ReferenceStr         OUT VARCHAR2);
 
 /*--------------------------------------------------------------------*
  *  Procedure used to acquire DDL Table PartKeys from PARTCOL$        *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSDDLTBLPARTKEYS
    (RowsToGet             IN INTEGER,
     ObjectNumIn           IN INTEGER,
     KeyNum               OUT t_tblbbyte,
     KeyPos               OUT t_tblbbyte);
 
 /*--------------------------------------------------------------------*
  *  Procedure used to acquire DDL Table SubPartKeys from SUBPARTCOL$  *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSDDLTBLSUBPARTKEYS
    (RowsToGet             IN INTEGER,
     ObjectNumIn           IN INTEGER,
     KeyNum               OUT t_tblbbyte,
     KeyPos               OUT t_tblbbyte);
 
 /*--------------------------------------------------------------------*
  *  Procedure used to acquire DDL Table Partitions OBJ$,TABPARTS, etc *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSDDLTBLPARTSLOT
    (RowsToGet             IN INTEGER,
     ObjectNumIn           IN INTEGER,
     PartObjNum           OUT t_tblbbyte,
     PartNum              OUT t_tblbbyte,
     PctgFree             OUT t_tblbbyte,
     PctgUsed             OUT t_tblbbyte,
     InitTran             OUT t_tblbbyte,
     MaxTran              OUT t_tblbbyte,
     InitExt              OUT t_tblbbyte,
     NextExt              OUT t_tblbbyte,
     MinExt               OUT t_tblbbyte,
     MaxExt               OUT t_tblbbyte,
     PctIncr              OUT t_tblbbyte,
     Lists                OUT t_tblbbyte,
     Groups               OUT t_tblbbyte,
     TsBlkSize            OUT t_tblbbyte,
     HiBndLen             OUT t_tblbbyte,
     LogFlag              OUT t_tblcbyte,
     BPool                OUT t_tblcbyte,
     Comp                 OUT t_tblcbyte,
     PartName             OUT t_subname,
     TSName               OUT t_tsname,
     HiBndVal             OUT t_hibound);
 
 /*--------------------------------------------------------------------*
  *  Procedure used to acquire COMPOSITE Partitions OBJ$,TABCOMPART    *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSDDLTBLCOMPARTSLOT
    (RowsToGet             IN INTEGER,
     ObjectNumIn           IN INTEGER,
     PartObjNum           OUT t_tblbbyte,
     PartNum              OUT t_tblbbyte,
     PctgFree             OUT t_tblbbyte,
     PctgUsed             OUT t_tblbbyte,
     InitTran             OUT t_tblbbyte,
     MaxTran              OUT t_tblbbyte,
     InitExt              OUT t_tblbbyte,
     NextExt              OUT t_tblbbyte,
     MinExt               OUT t_tblbbyte,
     MaxExt               OUT t_tblbbyte,
     PctIncr              OUT t_tblbbyte,
     Lists                OUT t_tblbbyte,
     Groups               OUT t_tblbbyte,
     TsBlkSize            OUT t_tblbbyte,
     HiBndLen             OUT t_tblbbyte,
     LogFlag              OUT t_tblcbyte,
     BPool                OUT t_tblcbyte,
     Comp                 OUT t_tblcbyte,
     PartName             OUT t_subname,
     TSName               OUT t_tsname,
     HiBndVal             OUT t_hibound,
     SubPartCnt           OUT t_tblbbyte);
 
 /*--------------------------------------------------------------------*
  *  Procedure used to acquire Table SubPartitions OBJ$,TABSUBPART$ etc*
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSDDLTBLSUBPARTSLOT
    (RowsToGet             IN INTEGER,
     ObjectNumIn           IN INTEGER,
     SubPartObjNum        OUT t_tblbbyte,
     SubPartNum           OUT t_tblbbyte,
     PctgFree             OUT t_tblbbyte,
     PctgUsed             OUT t_tblbbyte,
     InitTran             OUT t_tblbbyte,
     MaxTran              OUT t_tblbbyte,
     InitExt              OUT t_tblbbyte,
     NextExt              OUT t_tblbbyte,
     MinExt               OUT t_tblbbyte,
     MaxExt               OUT t_tblbbyte,
     PctIncr              OUT t_tblbbyte,
     Lists                OUT t_tblbbyte,
     Groups               OUT t_tblbbyte,
     TsBlkSize            OUT t_tblbbyte,
     LogFlag              OUT t_tblcbyte,
     BPool                OUT t_tblcbyte,
     PartName             OUT t_subname,
     TSName               OUT t_tsname,
     HiBndLen             OUT t_tblbbyte,
     HiBndVal             OUT t_hibound);
 
 /*--------------------------------------------------------------------*
  *  Procedure used to acquire IOT data from IND$,TS$,SEG$             *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSTBLIOTBASE
    (RowsToGet             IN INTEGER,
     ObjectNumIn           IN INTEGER,
     PctgFree             OUT INTEGER,
     PctgThres            OUT INTEGER,
     InitTran             OUT INTEGER,
     MaxTran              OUT INTEGER,
     InitExt              OUT INTEGER,
     NextExt              OUT INTEGER,
     MinExt               OUT INTEGER,
     MaxExt               OUT INTEGER,
     PctIncr              OUT INTEGER,
     Lists                OUT INTEGER,
     Groups               OUT INTEGER,
     TsBlkSize            OUT INTEGER,
     InclCol              OUT INTEGER,
     LogFlag              OUT CHAR,
     BPool                OUT CHAR,
     TSName               OUT VARCHAR2,
     CompCols             OUT INTEGER);
 
 /*--------------------------------------------------------------------*
  *  Procedure used to acquire IOT data from IND$,TS$,SEG$             *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSTBLIOTOVER
    (RowsToGet             IN INTEGER,
     ObjectNumIn           IN INTEGER,
     PctgFree             OUT INTEGER,
     PctgUsed             OUT INTEGER,
     InitTran             OUT INTEGER,
     MaxTran              OUT INTEGER,
     InitExt              OUT INTEGER,
     NextExt              OUT INTEGER,
     MinExt               OUT INTEGER,
     MaxExt               OUT INTEGER,
     PctIncr              OUT INTEGER,
     Lists                OUT INTEGER,
     Groups               OUT INTEGER,
     TsBlkSize            OUT INTEGER,
     LogFlag              OUT CHAR,
     BPool                OUT CHAR,
     TSName               OUT VARCHAR2);
 
 /*--------------------------------------------------------------------*
  *  Procedure used to acquire Table LOBs from LOB$,IND$,TS$,SEG$      *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSTBLLOBBASE
    (RowsToGet             IN INTEGER,
     ObjectNumIn           IN INTEGER,
     LobCol               OUT t_tblbbyte,
     LobObj               OUT t_tblbbyte,
     LobIdx               OUT t_tblbbyte,
     LobChunk             OUT t_tblbbyte,
     PctVers              OUT t_tblbbyte,
     SInitExt             OUT t_tblbbyte,
     SNextExt             OUT t_tblbbyte,
     SMinExt              OUT t_tblbbyte,
     SMaxExt              OUT t_tblbbyte,
     SPctIncr             OUT t_tblbbyte,
     SLists               OUT t_tblbbyte,
     SGroups              OUT t_tblbbyte,
     STsBlkSize           OUT t_tblbbyte,
     InitTran             OUT t_tblbbyte,
     MaxTran              OUT t_tblbbyte,
     IInitExt             OUT t_tblbbyte,
     INextExt             OUT t_tblbbyte,
     IMinExt              OUT t_tblbbyte,
     IMaxExt              OUT t_tblbbyte,
     IPctIncr             OUT t_tblbbyte,
     ILists               OUT t_tblbbyte,
     IGroups              OUT t_tblbbyte,
     ITsBlkSize           OUT t_tblbbyte,
     RowStg               OUT t_tblcbyte,
     LobFlags             OUT t_tblbbyte,
     SegBPool             OUT t_tblcbyte,
     IdxLog               OUT t_tblcbyte,
     IdxBPool             OUT t_tblcbyte,
     SegSysName           OUT t_tblcbyte,
     IdxSysName           OUT t_tblcbyte,
     SegName              OUT t_tablename,
     SegTSName            OUT t_tsname,
     IdxName              OUT t_tablename,
     IdxTSName            OUT t_tsname,
     Freepools            OUT t_tblbbyte,
     SecureFile           OUT t_tblcbyte,
     SegCre				 OUT t_segcre);
 
 /*--------------------------------------------------------------------*
  *  Procedure used to acquire Part LOBs from LOBFRAG$,TS$,SEG$,OBJ$   *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSPARTLOB
    (RowsToGet             IN INTEGER,
     ObjectNumIn           IN INTEGER,
     SegObj               OUT t_tblbbyte,
     LobChunk             OUT t_tblbbyte,
     PctVers              OUT t_tblbbyte,
     SInitExt             OUT t_tblbbyte,
     SNextExt             OUT t_tblbbyte,
     SMinExt              OUT t_tblbbyte,
     SMaxExt              OUT t_tblbbyte,
     SPctIncr             OUT t_tblbbyte,
     SLists               OUT t_tblbbyte,
     SGroups              OUT t_tblbbyte,
     STsBlkSize           OUT t_tblbbyte,
     ColNum               OUT t_tblbbyte,
     RowStg               OUT t_tblcbyte,
     LobFlags             OUT t_tblbbyte,
     SegBPool             OUT t_tblcbyte,
     SegSysName           OUT t_tblcbyte,
     SegTSName            OUT t_tsname,
     SegName              OUT t_subname);
 
 /*--------------------------------------------------------------------*
  *  Procedure used to acquire SubPart LOBs from LOBFRAG$,TS$,SEG$,OBJ$*
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSSUBPARTLOB
    (RowsToGet             IN INTEGER,
     ObjectNumIn           IN INTEGER,
     SegObj               OUT t_tblbbyte,
     LobChunk             OUT t_tblbbyte,
     PctVers              OUT t_tblbbyte,
     SInitExt             OUT t_tblbbyte,
     SNextExt             OUT t_tblbbyte,
     SMinExt              OUT t_tblbbyte,
     SMaxExt              OUT t_tblbbyte,
     SPctIncr             OUT t_tblbbyte,
     SLists               OUT t_tblbbyte,
     SGroups              OUT t_tblbbyte,
     STsBlkSize           OUT t_tblbbyte,
     ColNum               OUT t_tblbbyte,
     RowStg               OUT t_tblcbyte,
     LobFlags             OUT t_tblbbyte,
     SegBPool             OUT t_tblcbyte,
     SegSysName           OUT t_tblcbyte,
     SegTSName            OUT t_tsname,
     SegName              OUT t_subname);
 
 /*--------------------------------------------------------------------*
  *  Procedure used to acquire Part LOBs from LOBCOMPART$,TS$,LOB$,OBJ$*
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSCOMPARTLOB
    (RowsToGet             IN INTEGER,
     ObjectNumIn           IN INTEGER,
     SegObj               OUT t_tblbbyte,
     LobChunk             OUT t_tblbbyte,
     PctVers              OUT t_tblbbyte,
     SInitExt             OUT t_tblbbyte,
     SNextExt             OUT t_tblbbyte,
     SMinExt              OUT t_tblbbyte,
     SMaxExt              OUT t_tblbbyte,
     SPctIncr             OUT t_tblbbyte,
     SLists               OUT t_tblbbyte,
     SGroups              OUT t_tblbbyte,
     STsBlkSize           OUT t_tblbbyte,
     ColNum               OUT t_tblbbyte,
     RowStg               OUT t_tblcbyte,
     LobFlags             OUT t_tblbbyte,
     SegBPool             OUT t_tblcbyte,
     SegSysName           OUT t_tblcbyte,
     SegTSName            OUT t_tsname,
     SegName              OUT t_subname);
 
 /*--------------------------------------------------------------------*
  *  Procedure used to acquire default Part LOBs from PARTLOB$,COL$,TS$*
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSPARTDLOB
    (RowsToGet             IN INTEGER,
     ObjectNumIn           IN INTEGER,
     LobChunk             OUT t_tblbbyte,
     PctVers              OUT t_tblbbyte,
     SInitExt             OUT t_tblbbyte,
     SNextExt             OUT t_tblbbyte,
     SMinExt              OUT t_tblbbyte,
     SMaxExt              OUT t_tblbbyte,
     SPctIncr             OUT t_tblbbyte,
     SLists               OUT t_tblbbyte,
     SGroups              OUT t_tblbbyte,
     STsBlkSize           OUT t_tblbbyte,
     RowStg               OUT t_tblcbyte,
     LobFlags             OUT t_tblbbyte,
     SegBPool             OUT t_tblcbyte,
     ColName              OUT t_tablename,
     SegTSName            OUT t_tsname);
 
 /*--------------------------------------------------------------------*
  *  Procedure used to acquire Extended Attributes of View             *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSEXPVIEW
    (RowsToGet             IN INTEGER,
     ObjectNumIn           IN INTEGER,
     ViewLen              OUT INTEGER,
     ChkName              OUT VARCHAR2);
 
 /*--------------------------------------------------------------------*
  *  Procedure used to acquire Text of a View from VIEW$               *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSGETVIEW
    (RowsToGet             IN INTEGER,
     ObjectNumIn           IN INTEGER,
     OffsetNumIn           IN INTEGER,
     ColumnNumIn           IN INTEGER, /* not used */
     ViewText             OUT VARCHAR2);
 
 /*--------------------------------------------------------------------*
  *  Procedure used to acquire Table List from Creator/Table patterns  *
  *  when both names are explicit values                               *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSGETTBLLIST0
    (RowsToGet             IN INTEGER,
     ObjType1              IN INTEGER,
     ObjType2              IN INTEGER,
     ObjType3              IN INTEGER,
     CidPatternIn          IN VARCHAR2,
     TblPatternIn          IN VARCHAR2,
     CreatorName          OUT t_creatorname,
     TableName            OUT t_tablename,
     TableType            OUT t_tblcbyte,
     RowCount             OUT t_tblbbyte);
 
 /*--------------------------------------------------------------------*
  *  Procedure used to acquire Table List from Creator/Table patterns  *
  *  when Creator is a LIKE value and Table is explicit                *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSGETTBLLIST1
    (RowsToGet             IN INTEGER,
     ObjType1              IN INTEGER,
     ObjType2              IN INTEGER,
     ObjType3              IN INTEGER,
     CidPatternIn          IN VARCHAR2,
     TblPatternIn          IN VARCHAR2,
     CreatorName          OUT t_creatorname,
     TableName            OUT t_tablename,
     TableType            OUT t_tblcbyte,
     RowCount             OUT t_tblbbyte);
 
 /*--------------------------------------------------------------------*
  *  Procedure used to acquire Table List from Creator/Table patterns  *
  *  when Creator is explicit and Table is a LIKE value                *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSGETTBLLIST2
    (RowsToGet             IN INTEGER,
     ObjType1              IN INTEGER,
     ObjType2              IN INTEGER,
     ObjType3              IN INTEGER,
     CidPatternIn          IN VARCHAR2,
     TblPatternIn          IN VARCHAR2,
     CreatorName          OUT t_creatorname,
     TableName            OUT t_tablename,
     TableType            OUT t_tblcbyte,
     RowCount             OUT t_tblbbyte);
 
 /*--------------------------------------------------------------------*
  *  Procedure used to acquire Table List from Creator/Table patterns  *
  *  when both names are LIKE values                                   *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSGETTBLLIST3
    (RowsToGet             IN INTEGER,
     ObjType1              IN INTEGER,
     ObjType2              IN INTEGER,
     ObjType3              IN INTEGER,
     CidPatternIn          IN VARCHAR2,
     TblPatternIn          IN VARCHAR2,
     CreatorName          OUT t_creatorname,
     TableName            OUT t_tablename,
     TableType            OUT t_tblcbyte,
     RowCount             OUT t_tblbbyte);
 
 /*--------------------------------------------------------------------*
  *  Procedure used to acquire SubPartition Template Info              *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSGETSUBTEMPLATELIST
    (RowsToGet             IN INTEGER,
     ObjectNumIn           IN INTEGER,
     TSName               OUT t_tsname,
     Name                 OUT t_subname,
     HiBndVal             OUT t_hibound);
  END PSTO1IV0100_CSSTABLE;
/
CREATE OR REPLACE EDITIONABLE PACKAGE S022498.PSTO1IV0100_CSSTRIGGER  AS
 /*--------------------------------------------------------------------*
  *  Declare the PL/SQL Tables used by the Procedures in this package  *
  *--------------------------------------------------------------------*/
    TYPE t_ownername     IS TABLE OF SYS.DBA_USERS.USERNAME%TYPE
          INDEX BY BINARY_INTEGER;
    TYPE t_objectname       IS TABLE OF SYS.OBJ$.NAME%TYPE
          INDEX BY BINARY_INTEGER;
    TYPE t_integer       IS TABLE OF INTEGER
          INDEX BY BINARY_INTEGER;
    TYPE t_char          IS TABLE OF CHAR(1)
          INDEX BY BINARY_INTEGER;
    TYPE t_proctext      IS TABLE OF VARCHAR2(2000)
          INDEX BY BINARY_INTEGER;
 
 /*--------------------------------------------------------------------*
  *  Procedure used to acquire Trigger List from Table Object Number   *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSGETTRIGGER
    (RowsToGet             IN INTEGER,
     ObjectNumIn           IN INTEGER,
     ObjectNum            OUT t_integer,
     CidNum               OUT t_integer,
     TxtLen               OUT t_integer,
     Enabled              OUT t_char,
     Ins                  OUT t_char,
     Upd                  OUT t_char,
     Del                  OUT t_char,
     TrgTime              OUT t_char,
     TrgMode              OUT t_char,
     OwnerName            OUT t_ownername,
     TrgName              OUT t_objectname);
 
 /*--------------------------------------------------------------------*
  *  Procedure used to acquire Trigger Text for a known trigger        *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSGETTRGTEXT
    (RowsToGet             IN INTEGER,
     ObjectNumIn           IN INTEGER,
     OffsetNumIn           IN INTEGER,
     ColumnNumIn           IN INTEGER, /* not used */
     TrgText1             OUT VARCHAR2,
     TrgText2             OUT VARCHAR2);
 
 /*--------------------------------------------------------------------*
  *  Procedure used to get Extended Data for a specific Procedure      *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSGETPRCDATA
    (RowsToGet             IN INTEGER,
     CidName               IN VARCHAR2,
     PrcName               IN VARCHAR2,
     ObjectNum            OUT INTEGER,
     CidNum               OUT INTEGER,
     PrcSize              OUT INTEGER,
     Owner                OUT VARCHAR2,
     ProcName             OUT VARCHAR2);
 
 /*--------------------------------------------------------------------*
  *  Procedure used to get Extended data for a specific Function       *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSGETFUNDATA
    (RowsToGet             IN INTEGER,
     CidName               IN VARCHAR2,
     FunName               IN VARCHAR2,
     ObjectNum            OUT INTEGER,
     CidNum               OUT INTEGER,
     FunSize              OUT INTEGER,
     Owner                OUT VARCHAR2,
     FuncName             OUT VARCHAR2);
 
 /*--------------------------------------------------------------------*
  *  Procedure used to get Extended data for a specific Package        *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSGETPKGDATA
    (RowsToGet             IN INTEGER,
     CidName               IN VARCHAR2,
     PkgName               IN VARCHAR2,
     ObjectNum            OUT INTEGER,
     BodyNum              OUT INTEGER,
     CidNum               OUT INTEGER,
     PkgSize              OUT INTEGER,
     BdySize              OUT INTEGER,
     Owner                OUT VARCHAR2,
     PkgBName             OUT VARCHAR2);
 
 /*--------------------------------------------------------------------*
  *  Procedure used to get Text for Procedure,Function, Package        *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSGETPRCTEXT
    (RowsToGet             IN INTEGER,
     ObjectNumIn           IN INTEGER,
     PrcText1             OUT t_proctext,
     PrcText2             OUT t_proctext);
 
 /*--------------------------------------------------------------------*
  *  Procedure used to get Procedure List for explicit CID and Procs   *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSGETPRCLIST0
    (RowsToGet             IN INTEGER,
     CidPattern            IN VARCHAR2,
     PrcPattern            IN VARCHAR2,
     TypVar1               IN INTEGER,
     TypVar2               IN INTEGER,
     TypVar3               IN INTEGER,
     CreatorName          OUT t_ownername,
     ProcedureName        OUT t_objectname,
     SubType              OUT t_char);
 
 /*--------------------------------------------------------------------*
  *  Get Procedure List for wildcard CID and explicit Procedure name   *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSGETPRCLIST1
    (RowsToGet             IN INTEGER,
     CidPattern            IN VARCHAR2,
     PrcPattern            IN VARCHAR2,
     TypVar1               IN INTEGER,
     TypVar2               IN INTEGER,
     TypVar3               IN INTEGER,
     CreatorName          OUT t_ownername,
     ProcedureName        OUT t_objectname,
     SubType              OUT t_char);
 
 /*--------------------------------------------------------------------*
  *  Get Procedure List for explicit CID and wildcard Procedure name   *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSGETPRCLIST2
    (RowsToGet             IN INTEGER,
     CidPattern            IN VARCHAR2,
     PrcPattern            IN VARCHAR2,
     TypVar1               IN INTEGER,
     TypVar2               IN INTEGER,
     TypVar3               IN INTEGER,
     CreatorName          OUT t_ownername,
     ProcedureName        OUT t_objectname,
     SubType              OUT t_char);
 
 /*--------------------------------------------------------------------*
  *  Get Procedure List for wildcard CID and Procedure names           *
  *--------------------------------------------------------------------*/
  PROCEDURE PSTV0100_CSSGETPRCLIST3
    (RowsToGet             IN INTEGER,
     CidPattern            IN VARCHAR2,
     PrcPattern            IN VARCHAR2,
     TypVar1               IN INTEGER,
     TypVar2               IN INTEGER,
     TypVar3               IN INTEGER,
     CreatorName          OUT t_ownername,
     ProcedureName        OUT t_objectname,
     SubType              OUT t_char);
  END PSTO1IV0100_CSSTRIGGER;
/
GRANT DELETE ON PROD.ABSTRACT_EOB_ATTACHMENT TO S022498
/
GRANT DELETE ON PROD.ZIP_TO_CARRIER_LOCALITY TO S022498
/
GRANT DELETE ON PROD.BANK_ACCOUNT TO S022498
/
GRANT DELETE ON PROD.CLAIM_SEARCH_INPUT TO S022498
/
GRANT DELETE ON PROD.COB_POLICY TO S022498
/
GRANT DELETE ON PROD.CONSOLIDATED_CLAIM TO S022498
/
GRANT DELETE ON PROD.CONTACT_INFORMATION TO S022498
/
GRANT DELETE ON PROD.CONTACT_LIST TO S022498
/
GRANT DELETE ON PROD.CONVERTED_SUPPLIER_INVOICE TO S022498
/
GRANT DELETE ON PROD.CORRESPONDENCE_INFORMATION TO S022498
/
GRANT DELETE ON PROD.DENTAL_SUPPLIER_INVOICE TO S022498
/
GRANT DELETE ON PROD.HCFA1500 TO S022498
/
GRANT DELETE ON PROD.IDENTIFICATION_NUMBER TO S022498
/
GRANT DELETE ON PROD.INDIVIDUAL_INFORMATION TO S022498
/
GRANT DELETE ON PROD.INSURANCE_INFORMATION TO S022498
/
GRANT DELETE ON PROD.LICENSE_NUMBER TO S022498
/
GRANT DELETE ON PROD.MEDICARE_HICN_INFO TO S022498
/
GRANT DELETE ON PROD.MEMBER_LINK TO S022498
/
GRANT DELETE ON PROD.MEMBER_PHYSICAL_ADDRESS TO S022498
/
GRANT DELETE ON PROD.MEMBER_TYPE_INFO TO S022498
/
GRANT DELETE ON PROD.MEMBERSHIP TO S022498
/
GRANT DELETE ON PROD.ORGANIZATION_INFORMATION TO S022498
/
GRANT DELETE ON PROD.OTHER_ORGANIZATION_NAME_USED TO S022498
/
GRANT DELETE ON PROD.OTHER_RESPONSIBLE_PERSON_INFO TO S022498
/
GRANT DELETE ON PROD.PATIENT_INFO TO S022498
/
GRANT DELETE ON PROD.PER_MEMBER_PER_MONTH_BILL_LINE TO S022498
/
GRANT DELETE ON PROD.PERSON_NAME TO S022498
/
GRANT DELETE ON PROD.POSTAL_ADDRESS TO S022498
/
GRANT DELETE ON PROD.RBRVS_DETAILS TO S022498
/
GRANT DELETE ON PROD.SUBSCRIPTION TO S022498
/
GRANT DELETE ON PROD.SUBSCRIPTION_SELECTION TO S022498
/
GRANT DELETE ON PROD.SUPPLIER_INVOICE_PERSON_INFO TO S022498
/
GRANT DELETE ON PROD.TAX_ENTITY TO S022498
/
GRANT DELETE ON PROD.TELEPHONE TO S022498
/
GRANT DELETE ON PROD.UB92 TO S022498
/
GRANT DELETE ON PROD.USER_ACCOUNT TO S022498
/
GRANT DELETE ON PROD.ADDRESS_INFORMATION TO S022498
/
GRANT INSERT ON PROD.ABSTRACT_EOB_ATTACHMENT TO S022498
/
GRANT INSERT ON PROD.ZIP_TO_CARRIER_LOCALITY TO S022498
/
GRANT INSERT ON PROD.BANK_ACCOUNT TO S022498
/
GRANT INSERT ON PROD.CLAIM_SEARCH_INPUT TO S022498
/
GRANT INSERT ON PROD.COB_POLICY TO S022498
/
GRANT INSERT ON PROD.CONSOLIDATED_CLAIM TO S022498
/
GRANT INSERT ON PROD.CONTACT_INFORMATION TO S022498
/
GRANT INSERT ON PROD.CONTACT_LIST TO S022498
/
GRANT INSERT ON PROD.CONVERTED_SUPPLIER_INVOICE TO S022498
/
GRANT INSERT ON PROD.CORRESPONDENCE_INFORMATION TO S022498
/
GRANT INSERT ON PROD.DENTAL_SUPPLIER_INVOICE TO S022498
/
GRANT INSERT ON PROD.HCFA1500 TO S022498
/
GRANT INSERT ON PROD.IDENTIFICATION_NUMBER TO S022498
/
GRANT INSERT ON PROD.INDIVIDUAL_INFORMATION TO S022498
/
GRANT INSERT ON PROD.INSURANCE_INFORMATION TO S022498
/
GRANT INSERT ON PROD.LICENSE_NUMBER TO S022498
/
GRANT INSERT ON PROD.MEDICARE_HICN_INFO TO S022498
/
GRANT INSERT ON PROD.MEMBER_LINK TO S022498
/
GRANT INSERT ON PROD.MEMBER_PHYSICAL_ADDRESS TO S022498
/
GRANT INSERT ON PROD.MEMBER_TYPE_INFO TO S022498
/
GRANT INSERT ON PROD.MEMBERSHIP TO S022498
/
GRANT INSERT ON PROD.ORGANIZATION_INFORMATION TO S022498
/
GRANT INSERT ON PROD.OTHER_ORGANIZATION_NAME_USED TO S022498
/
GRANT INSERT ON PROD.OTHER_RESPONSIBLE_PERSON_INFO TO S022498
/
GRANT INSERT ON PROD.PATIENT_INFO TO S022498
/
GRANT INSERT ON PROD.PER_MEMBER_PER_MONTH_BILL_LINE TO S022498
/
GRANT INSERT ON PROD.PERSON_NAME TO S022498
/
GRANT INSERT ON PROD.POSTAL_ADDRESS TO S022498
/
GRANT INSERT ON PROD.RBRVS_DETAILS TO S022498
/
GRANT INSERT ON PROD.SUBSCRIPTION TO S022498
/
GRANT INSERT ON PROD.SUBSCRIPTION_SELECTION TO S022498
/
GRANT INSERT ON PROD.SUPPLIER_INVOICE_PERSON_INFO TO S022498
/
GRANT INSERT ON PROD.TAX_ENTITY TO S022498
/
GRANT INSERT ON PROD.TELEPHONE TO S022498
/
GRANT INSERT ON PROD.UB92 TO S022498
/
GRANT INSERT ON PROD.USER_ACCOUNT TO S022498
/
GRANT INSERT ON PROD.ADDRESS_INFORMATION TO S022498
/
GRANT SELECT ON SYS.ENC$ TO S022498
/
GRANT SELECT ON SYS.USER$ TO S022498
/
GRANT SELECT ON PROD.ABSTRACT_EOB_ATTACHMENT TO S022498
/
GRANT SELECT ON PROD.ADDRESS_INFORMATION TO S022498
/
GRANT SELECT ON PROD.BANK_ACCOUNT TO S022498
/
GRANT SELECT ON PROD.CLAIM_SEARCH_INPUT TO S022498
/
GRANT SELECT ON PROD.COB_POLICY TO S022498
/
GRANT SELECT ON PROD.CONSOLIDATED_CLAIM TO S022498
/
GRANT SELECT ON PROD.CONTACT_INFORMATION TO S022498
/
GRANT SELECT ON PROD.CONTACT_LIST TO S022498
/
GRANT SELECT ON PROD.CONVERTED_SUPPLIER_INVOICE TO S022498
/
GRANT SELECT ON PROD.CORRESPONDENCE_INFORMATION TO S022498
/
GRANT SELECT ON PROD.DENTAL_SUPPLIER_INVOICE TO S022498
/
GRANT SELECT ON PROD.HCFA1500 TO S022498
/
GRANT SELECT ON PROD.IDENTIFICATION_NUMBER TO S022498
/
GRANT SELECT ON PROD.INDIVIDUAL_INFORMATION TO S022498
/
GRANT SELECT ON PROD.INSURANCE_INFORMATION TO S022498
/
GRANT SELECT ON PROD.LICENSE_NUMBER TO S022498
/
GRANT SELECT ON PROD.MEDICARE_HICN_INFO TO S022498
/
GRANT SELECT ON PROD.MEMBER_LINK TO S022498
/
GRANT SELECT ON PROD.MEMBER_PHYSICAL_ADDRESS TO S022498
/
GRANT SELECT ON PROD.MEMBER_TYPE_INFO TO S022498
/
GRANT SELECT ON PROD.MEMBERSHIP TO S022498
/
GRANT SELECT ON PROD.ORGANIZATION_INFORMATION TO S022498
/
GRANT SELECT ON PROD.OTHER_ORGANIZATION_NAME_USED TO S022498
/
GRANT SELECT ON PROD.OTHER_RESPONSIBLE_PERSON_INFO TO S022498
/
GRANT SELECT ON PROD.PATIENT_INFO TO S022498
/
GRANT SELECT ON PROD.PER_MEMBER_PER_MONTH_BILL_LINE TO S022498
/
GRANT SELECT ON PROD.PERSON_NAME TO S022498
/
GRANT SELECT ON PROD.POSTAL_ADDRESS TO S022498
/
GRANT SELECT ON PROD.RBRVS_DETAILS TO S022498
/
GRANT SELECT ON PROD.SUBSCRIPTION TO S022498
/
GRANT SELECT ON PROD.SUBSCRIPTION_SELECTION TO S022498
/
GRANT SELECT ON PROD.SUPPLIER_INVOICE_PERSON_INFO TO S022498
/
GRANT SELECT ON PROD.TAX_ENTITY TO S022498
/
GRANT SELECT ON PROD.TELEPHONE TO S022498
/
GRANT SELECT ON PROD.UB92 TO S022498
/
GRANT SELECT ON PROD.USER_ACCOUNT TO S022498
/
GRANT SELECT ON PROD.ZIP_TO_CARRIER_LOCALITY TO S022498
/
GRANT UPDATE ON PROD.ABSTRACT_EOB_ATTACHMENT TO S022498
/
GRANT UPDATE ON PROD.ZIP_TO_CARRIER_LOCALITY TO S022498
/
GRANT UPDATE ON PROD.BANK_ACCOUNT TO S022498
/
GRANT UPDATE ON PROD.CLAIM_SEARCH_INPUT TO S022498
/
GRANT UPDATE ON PROD.COB_POLICY TO S022498
/
GRANT UPDATE ON PROD.CONSOLIDATED_CLAIM TO S022498
/
GRANT UPDATE ON PROD.CONTACT_INFORMATION TO S022498
/
GRANT UPDATE ON PROD.CONTACT_LIST TO S022498
/
GRANT UPDATE ON PROD.CONVERTED_SUPPLIER_INVOICE TO S022498
/
GRANT UPDATE ON PROD.CORRESPONDENCE_INFORMATION TO S022498
/
GRANT UPDATE ON PROD.DENTAL_SUPPLIER_INVOICE TO S022498
/
GRANT UPDATE ON PROD.HCFA1500 TO S022498
/
GRANT UPDATE ON PROD.IDENTIFICATION_NUMBER TO S022498
/
GRANT UPDATE ON PROD.INDIVIDUAL_INFORMATION TO S022498
/
GRANT UPDATE ON PROD.INSURANCE_INFORMATION TO S022498
/
GRANT UPDATE ON PROD.LICENSE_NUMBER TO S022498
/
GRANT UPDATE ON PROD.MEDICARE_HICN_INFO TO S022498
/
GRANT UPDATE ON PROD.MEMBER_LINK TO S022498
/
GRANT UPDATE ON PROD.MEMBER_PHYSICAL_ADDRESS TO S022498
/
GRANT UPDATE ON PROD.MEMBER_TYPE_INFO TO S022498
/
GRANT UPDATE ON PROD.MEMBERSHIP TO S022498
/
GRANT UPDATE ON PROD.ORGANIZATION_INFORMATION TO S022498
/
GRANT UPDATE ON PROD.OTHER_ORGANIZATION_NAME_USED TO S022498
/
GRANT UPDATE ON PROD.OTHER_RESPONSIBLE_PERSON_INFO TO S022498
/
GRANT UPDATE ON PROD.PATIENT_INFO TO S022498
/
GRANT UPDATE ON PROD.PER_MEMBER_PER_MONTH_BILL_LINE TO S022498
/
GRANT UPDATE ON PROD.PERSON_NAME TO S022498
/
GRANT UPDATE ON PROD.POSTAL_ADDRESS TO S022498
/
GRANT UPDATE ON PROD.RBRVS_DETAILS TO S022498
/
GRANT UPDATE ON PROD.SUBSCRIPTION TO S022498
/
GRANT UPDATE ON PROD.SUBSCRIPTION_SELECTION TO S022498
/
GRANT UPDATE ON PROD.SUPPLIER_INVOICE_PERSON_INFO TO S022498
/
GRANT UPDATE ON PROD.TAX_ENTITY TO S022498
/
GRANT UPDATE ON PROD.TELEPHONE TO S022498
/
GRANT UPDATE ON PROD.UB92 TO S022498
/
GRANT UPDATE ON PROD.USER_ACCOUNT TO S022498
/
GRANT UPDATE ON PROD.ADDRESS_INFORMATION TO S022498
/
GRANT CREATE PROCEDURE TO S022498
/
GRANT CREATE SESSION TO S022498
/
GRANT CREATE TABLE TO S022498
/
GRANT CREATE VIEW TO S022498
/
GRANT SELECT ANY DICTIONARY TO S022498
/
GRANT UNLIMITED TABLESPACE TO S022498
/
GRANT EXECUTE ON S022498.PSTO1IV0100_CSSCHECK TO "PUBLIC"
/
GRANT EXECUTE ON S022498.PSTO1IV0100_CSSCHECKNAMESPACE TO "PUBLIC"
/
GRANT EXECUTE ON S022498.PSTO1IV0100_CSSCID TO "PUBLIC"
/
GRANT EXECUTE ON S022498.PSTO1IV0100_CSSCOLUMN TO "PUBLIC"
/
GRANT EXECUTE ON S022498.PSTO1IV0100_CSSENCRYPT TO "PUBLIC"
/
GRANT EXECUTE ON S022498.PSTO1IV0100_CSSEXECUTE TO "PUBLIC"
/
GRANT EXECUTE ON S022498.PSTO1IV0100_CSSINDEX TO "PUBLIC"
/
GRANT EXECUTE ON S022498.PSTO1IV0100_CSSPKDEF TO "PUBLIC"
/
GRANT EXECUTE ON S022498.PSTO1IV0100_CSSRELCON TO "PUBLIC"
/
GRANT EXECUTE ON S022498.PSTO1IV0100_CSSSEQUENCE TO "PUBLIC"
/
GRANT EXECUTE ON S022498.PSTO1IV0100_CSSSPCMGT TO "PUBLIC"
/
GRANT EXECUTE ON S022498.PSTO1IV0100_CSSSYNONYM TO "PUBLIC"
/
GRANT EXECUTE ON S022498.PSTO1IV0100_CSSTABLE TO "PUBLIC"
/
GRANT EXECUTE ON S022498.PSTO1IV0100_CSSTRIGGER TO "PUBLIC"
/
