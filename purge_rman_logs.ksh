###Script to purge ivpr01 Rman Log files####

export PRODDIR=${PRODDIR:-/ivpr01}
export LOGDIR=$PRODDIR/logs

/usr/bin/find $LOGDIR -name \*.log -mtime +31 -exec rm -f {} \;

#echo $LOGDIR
