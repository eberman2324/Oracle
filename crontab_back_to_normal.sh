
#Erase
crontab -r

wait

#Activate regular crontab after all HRP ugrade scripts completed
crontab /home/oracle/eb/GRP/crontab_back_to_normal.lst