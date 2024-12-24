
# new standard
# Set To Script Directory
SCRDIR="/oradb/app/oracle/local/scripts/HRP_upgrade"
SCR=/oradb/app/oracle/local/scripts





# Remove From Previous Run

if [ -f ${SCRDIR}/crontab_back_to_normal.lst ] ; then
   rm ${SCRDIR}/crontab_back_to_normal.lst
fi


#Make copy of current crontab
crontab -l > ${SCRDIR}/crontab_back_to_normal.lst

# Create during grp crontab version
crontab -l |egrep -iv "kill_jobs|gather_" > crontab_during_grp.lst
#Create after grp drop crontab version
crontab -l |egrep -iv "gather_fee_detail_stats|gather_claim_adj|gather_weekly_stats|gather_cvc_stats_wkly|gather_supp_by_other_id_stats|gather_pract_mem_stats" > crontab_after_grp_drop.lst

#Erase
crontab -r

wait
#Activate Upgrade Version of crontab
crontab ${SCRDIR}/crontab_during_grp.lst