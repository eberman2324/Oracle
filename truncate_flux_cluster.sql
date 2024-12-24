set trimspool on

spool &1._truncate_flux_cluster_&2..out

set echo on 

truncate table prod.flux_cluster;
