#!/bin/sh

clear

for db in "HEPYQA" "HEPYQA2" "HEPYQA3" "HEPYUAT" "HECVQA" "HECVQA2" "HECVQA3" "HECVUAT"
do

# Get Uptime
case ${db} in
     "HEPYQA")
     echo "Uptime For Server `hostname -s`"
     uptime 
     host=xhepydbm21q
     echo "Uptime For Server ${host}"
     ssh -q ${host} uptime
     ;;
     "HEPYQA2")
     host=xhepydbw22q
     echo "Uptime For Server ${host}"
     ssh -q ${host} uptime
     ;;
     "HEPYQA3")
     host=xhepydbw23q
     echo "Uptime For Server ${host}"
     ssh -q ${host} uptime
     ;;
     "HEPYUAT")
     host=xhepydbwu21q
     echo "Uptime For Server ${host}"
     ssh -q ${host} uptime 
     ;;
     "HECVQA")
     host=xhecvdbw21q
     echo "Uptime For Server ${host}"
     ssh -q ${host} uptime 
     ;;
     "HECVQA2")
     host=xhecvdbw22q
     echo "Uptime For Server ${host}"
     ssh -q ${host} uptime 
     ;;
     "HECVQA3")
     host=xhecvdbw23q
     echo "Uptime For Server ${host}"
     ssh -q ${host} uptime 
     ;;
     "HECVUAT")
     host=xhecvdbwu21q
     echo "Uptime For Server ${host}"
     ssh -q ${host} uptime 
     ;;
     *)
     echo
     echo "${db} Not A Recognized PAYOR QA or UAT DataBase - DataBase Skipped"
     echo
     continue
     ;;      
esac

done

