#!/bin/bash
for i in `oracleasm listdisks`
do
oracleasm querydisk -d $i
done
echo
ls -l /dev/dm*

