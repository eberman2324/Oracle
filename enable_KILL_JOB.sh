
# new standard
# Set To Script Directory
SCRDIR="/oradb/app/oracle/local/scripts/HRP_upgrade"
SCR=/oradb/app/oracle/local/scripts




#Erase
crontab -r

wait

#Activate after grp drop crontab
###crontab /home/oracle/eb/GRP/crontab_after_grp_drop.lst
crontab ${SCRDIR}/crontab_back_to_normal.lst