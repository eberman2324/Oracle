*************** ACL **********************************************************************************************************************************
The DBMS_NETWORK_ACL_ADMIN package provides the interface to administer the network access control lists (ACL).

ACLs are used to control access by users to external network services and resources from the database through PL/SQL network utility packages including UTL_TCP , UTL_HTTP , UTL_SMTP and UTL_INADDR .

Example below is setup for Database to be able access LDAP info used in create new user script.

********************************************************************************************************************************************************


1. Grant following priv to any existing or new DBA account (option as long as account has DBA it should do it)

GRANT APP_ICR_ROLE TO A603481 WITH ADMIN OPTION
/
GRANT "CONNECT" TO A603481
/
GRANT DBA TO A603481
/
ALTER USER A603481 DEFAULT ROLE DBA
/
GRANT EXECUTE ON AEDBA.AD_PKG TO A603481
/
GRANT EXECUTE ON AEDBA.AD_USER_T TO A603481
/
GRANT EXECUTE ON AEDBA.AD_USER_CT TO A603481
/
GRANT INSERT ON AEDBA.AD_CONFIG TO A603481
/
GRANT SELECT ON AEDBA.AD_CONFIG TO A603481
/
GRANT UPDATE ON AEDBA.AD_CONFIG TO A603481
/
GRANT UNLIMITED TABLESPACE TO A603481
/

2. Deploy ACL package under pre determine schema. AEDBA in HEPYDEV example

sqlplus / as sysdba
@AD_PKG.sql


3. Deploy AD_CONFIG table

sqlplus / as sysdba
@AD_CONFIG.sql

Insert following records

CONFIG_VAR	CONFIG_VAL			NOTES	INACTIVE_DT	CONFIG_VAL2
ADCVTYAUTH	dataservices			[NULL]	[NULL]		[NULL]
ADCVTYBASE	DC=cvty,DC=com			[NULL]	[NULL]		[NULL]
ADCVTYHOST	ldap.cvty.com			[NULL]	[NULL]		[NULL]
ADCVTYPORT	389				[NULL]	[NULL]		[NULL]
ADCVTYPW	LaxEdi745678wNm			[NULL]	[NULL]		[NULL]
ADAETHAUTH	aeth\S060561			[NULL]	[NULL]		[NULL]
ADAETHBASE	dc=aeth,dc=aetna,dc=com		[NULL]	[NULL]		[NULL]
ADAETHHOST	ADLDAP.AETH.AETNA.COM		[NULL]	[NULL]		[NULL]
ADAETHPORT	389				[NULL]	[NULL]		[NULL]
ADAETHPW	Y@NZY7UQ			[NULL]	[NULL]		[NULL]
CVS_RX_AD_AUTH	SRV_ICRAD			[NULL]	[NULL]		[NULL]
CVS_RX_AD_BASE	DC=caremarkrx,DC=net		[NULL]	[NULL]		[NULL]
CVS_RX_AD_PORT	389				[NULL]	[NULL]		[NULL]
CVS_RX_AD_PW	Ready2work			[NULL]	[NULL]		[NULL]
CVS_RX_AD_SVR	msldap.caremarkrx.net		[NULL]	[NULL]		[NULL]
CVS_AD_AUTH	srv_icr				[NULL]	[NULL]		[NULL]
CVS_AD_BASE	DC=corp,DC=cvscaremark,DC=com	[NULL]	[NULL]		[NULL]
CVS_AD_PORT	389				[NULL]	[NULL]		[NULL]
CVS_AD_PW	Ready2work			[NULL]	[NULL]		[NULL]
CVS_AD_SVR	10.6.74.52			[NULL]	[NULL]		[NULL]


4. Config ACL

sqlplus / as sysdba
@acl.sql

(in case of rollback execute following script @acl_rollback.sql


5. Make approprite changes in new user scripts to call new ldap script. 

Example:

get_ldap_user_info_eb.sql