#!/bin/bash
echo "  " ;echo "HOSTNAME:  " `hostname` ;echo "  " ;
echo "Number of CPUs: " `cat /proc/cpuinfo | grep -i 'model name' | wc -l` ; echo "  " `cat /proc/cpuinfo | grep -i 'model name' | uniq` ; echo " "
echo "MEMORY:  " ; free -m ; echo "  ";
echo "HUGE PAGES: " ; cat /proc/meminfo | grep -i 'HugePages_Total' 
cat /proc/meminfo | grep -i 'HugePages_Free' ; echo " "
#  -rwxr-xr-x 1 oracle dba      389 Oct 22 15:03 BOX.sh
