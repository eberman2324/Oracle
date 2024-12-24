LOAD DATA
INFILE	'/aetnaprod/backup/ivr_hig/Home_Depot_Received_Daily.ttx'
BADFILE	'/aetnaprod/backup/sqlloader/ivr_hig.bad'
DISCARDFILE '/aetnaprod/backup/sqlloader/ivr_hig.dsc'
APPEND INTO TABLE ivr.ivr_thd_claims
FIELDS TERMINATED BY X'9' OPTIONALLY ENCLOSED BY '"' TRAILING NULLCOLS
(CLAIM_NUMBER,LAST_NAME,FIRST_NAME,CLIENT_ID,COMPANY_NAME)


