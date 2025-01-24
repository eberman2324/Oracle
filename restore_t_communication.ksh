#!/bin/ksh
PIPE=/tmp/tmp.pipe
rm /tmp/tmp.pipe
mknod $PIPE p

uncompress -c  09132008010000/fullwkabprod.exp.09132008010000.Z > $PIPE &

imp parfile=restore_t_communication.par userid=system/no734s file=$PIPE log=restore_t_communication.log
