set echo on 

drop role COMET_GATEWAY;

spool create_comet_role_${ORACLE_SID}.out

create role COMET_GATEWAY;

grant select on phc_rxp.RX_ORDERS		to COMET_GATEWAY;
Grant select on apps.hz_parties			to COMET_GATEWAY;
Grant select on apps.aso_shipments		to COMET_GATEWAY;
Grant select on apps.wsh_carrier_services_v	to COMET_GATEWAY;
Grant select on apps.wsh_carriers_v		to COMET_GATEWAY;
Grant select on apps.hz_contact_points		to COMET_GATEWAY;
Grant select on apps.hz_contact_preferences	to COMET_GATEWAY;
Grant select on apps.rx_order_lines		to COMET_GATEWAY;
Grant select on apps.hz_cust_accounts		to COMET_GATEWAY;
Grant select on AR.hz_customer_profiles		to COMET_GATEWAY;
Grant select on PHC_RXP.Rx_Payments 		to COMET_GATEWAY;

Grant EXECUTE on apps.ASRX_NAV_EMAIL_RX_NUMBER	to COMET_GATEWAY;
Grant EXECUTE on apps.ASRX_NAV_WEBSERV_PKG	to COMET_GATEWAY;
Grant EXECUTE on APPS.ASRX_NAV_EMAIL_UPDATE	to COMET_GATEWAY;
Grant EXECUTE on phc_rxp.phc_rx_payments	to COMET_GATEWAY;
Grant EXECUTE on apps.fnd_profile		TO COMET_GATEWAY;

SPOOL OFF;
EXIT;

--
--
