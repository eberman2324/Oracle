set serveroutput on
DECLARE 
blkcnt_cnt pls_integer; 
blkcnt_uncmp pls_integer;
blkcnt_cmp pls_integer;
row_cmp pls_integer;
row_uncmp pls_integer;
cmp_ratio pls_integer;
comptype_str varchar2(100);
BEGIN
DBMS_COMPRESSION.GET_COMPRESSION_RATIO ('PROD', 'PROD', 'BLOB_CONSOLIDATED_CLAIM', '', DBMS_COMPRESSION.COMP_ADVANCED, blkcnt_cmp, blkcnt_uncmp, row_cmp, row_uncmp, cmp_ratio, comptype_str); 
DBMS_OUTPUT.PUT_LINE('Block count compressed = '|| blkcnt_cmp);
DBMS_OUTPUT.PUT_LINE('Block count uncompressed = '|| blkcnt_uncmp); 
DBMS_OUTPUT.PUT_LINE('Row count per block compressed = '|| row_cmp); 
DBMS_OUTPUT.PUT_LINE('Row count per block uncompressed = '|| row_uncmp); 
DBMS_OUTPUT.PUT_LINE('Compression type = '|| comptype_str);
DBMS_OUTPUT.PUT_LINE('Compression ratio = '|| cmp_ratio); 
END;
/