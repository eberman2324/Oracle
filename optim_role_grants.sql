set echo on trimspool on

spool &1._optim_role_grants.out

CREATE ROLE OPTIM NOT IDENTIFIED
/
GRANT DELETE ON PROD.ABSTRACT_EOB_ATTACHMENT TO OPTIM
/
GRANT DELETE ON PROD.MEMBER_PHYSICAL_ADDRESS TO OPTIM
/
GRANT DELETE ON PROD.ZIP_TO_CARRIER_LOCALITY TO OPTIM
/
GRANT DELETE ON PROD.UB92 TO OPTIM
/
GRANT DELETE ON PROD.TELEPHONE TO OPTIM
/
GRANT DELETE ON PROD.TAX_ENTITY TO OPTIM
/
GRANT DELETE ON PROD.RBRVS_DETAILS TO OPTIM
/
GRANT DELETE ON PROD.POSTAL_ADDRESS TO OPTIM
/
GRANT DELETE ON PROD.PERSON_NAME TO OPTIM
/
GRANT DELETE ON PROD.PER_MEMBER_PER_MONTH_BILL_LINE TO OPTIM
/
GRANT DELETE ON PROD.PATIENT_INFO TO OPTIM
/
GRANT DELETE ON PROD.OTHER_ORGANIZATION_NAME_USED TO OPTIM
/
GRANT DELETE ON PROD.ORGANIZATION_INFORMATION TO OPTIM
/
GRANT DELETE ON PROD.MEMBER_LINK TO OPTIM
/
GRANT DELETE ON PROD.LICENSE_NUMBER TO OPTIM
/
GRANT DELETE ON PROD.INSURANCE_INFORMATION TO OPTIM
/
GRANT DELETE ON PROD.INDIVIDUAL_INFORMATION TO OPTIM
/
GRANT DELETE ON PROD.IDENTIFICATION_NUMBER TO OPTIM
/
GRANT DELETE ON PROD.HCFA1500 TO OPTIM
/
GRANT DELETE ON PROD.DENTAL_SUPPLIER_INVOICE TO OPTIM
/
GRANT DELETE ON PROD.CORRESPONDENCE_INFORMATION TO OPTIM
/
GRANT DELETE ON PROD.BANK_ACCOUNT TO OPTIM
/
GRANT DELETE ON PROD.ADDRESS_INFORMATION TO OPTIM
/
GRANT DELETE ON PROD.CLAIM_SEARCH_INPUT TO OPTIM
/
GRANT DELETE ON PROD.CONSOLIDATED_CLAIM TO OPTIM
/
GRANT DELETE ON PROD.CONVERTED_SUPPLIER_INVOICE TO OPTIM
/
GRANT DELETE ON PROD.MEMBER_TYPE_INFO TO OPTIM
/
GRANT DELETE ON PROD.SUBSCRIPTION TO OPTIM
/
GRANT DELETE ON PROD.SUBSCRIPTION_SELECTION TO OPTIM
/
GRANT INSERT ON PROD.MEMBER_PHYSICAL_ADDRESS TO OPTIM
/
GRANT INSERT ON PROD.ABSTRACT_EOB_ATTACHMENT TO OPTIM
/
GRANT INSERT ON PROD.MEMBER_LINK TO OPTIM
/
GRANT INSERT ON PROD.PERSON_NAME TO OPTIM
/
GRANT INSERT ON PROD.LICENSE_NUMBER TO OPTIM
/
GRANT INSERT ON PROD.TELEPHONE TO OPTIM
/
GRANT INSERT ON PROD.INSURANCE_INFORMATION TO OPTIM
/
GRANT INSERT ON PROD.PER_MEMBER_PER_MONTH_BILL_LINE TO OPTIM
/
GRANT INSERT ON PROD.INDIVIDUAL_INFORMATION TO OPTIM
/
GRANT INSERT ON PROD.RBRVS_DETAILS TO OPTIM
/
GRANT INSERT ON PROD.IDENTIFICATION_NUMBER TO OPTIM
/
GRANT INSERT ON PROD.PATIENT_INFO TO OPTIM
/
GRANT INSERT ON PROD.HCFA1500 TO OPTIM
/
GRANT INSERT ON PROD.UB92 TO OPTIM
/
GRANT INSERT ON PROD.DENTAL_SUPPLIER_INVOICE TO OPTIM
/
GRANT INSERT ON PROD.OTHER_ORGANIZATION_NAME_USED TO OPTIM
/
GRANT INSERT ON PROD.CORRESPONDENCE_INFORMATION TO OPTIM
/
GRANT INSERT ON PROD.POSTAL_ADDRESS TO OPTIM
/
GRANT INSERT ON PROD.BANK_ACCOUNT TO OPTIM
/
GRANT INSERT ON PROD.ORGANIZATION_INFORMATION TO OPTIM
/
GRANT INSERT ON PROD.ADDRESS_INFORMATION TO OPTIM
/
GRANT INSERT ON PROD.TAX_ENTITY TO OPTIM
/
GRANT INSERT ON PROD.ZIP_TO_CARRIER_LOCALITY TO OPTIM
/
GRANT INSERT ON PROD.CLAIM_SEARCH_INPUT TO OPTIM
/
GRANT INSERT ON PROD.CONSOLIDATED_CLAIM TO OPTIM
/
GRANT INSERT ON PROD.CONVERTED_SUPPLIER_INVOICE TO OPTIM
/
GRANT INSERT ON PROD.MEMBER_TYPE_INFO TO OPTIM
/
GRANT INSERT ON PROD.SUBSCRIPTION TO OPTIM
/
GRANT INSERT ON PROD.SUBSCRIPTION_SELECTION TO OPTIM
/
GRANT SELECT ON SYS.ENC$ TO OPTIM
/
GRANT SELECT ON SYS.USER$ TO OPTIM
/
GRANT SELECT ON PROD.ABSTRACT_EOB_ATTACHMENT TO OPTIM
/
GRANT SELECT ON PROD.ADDRESS_INFORMATION TO OPTIM
/
GRANT SELECT ON PROD.BANK_ACCOUNT TO OPTIM
/
GRANT SELECT ON PROD.CORRESPONDENCE_INFORMATION TO OPTIM
/
GRANT SELECT ON PROD.DENTAL_SUPPLIER_INVOICE TO OPTIM
/
GRANT SELECT ON PROD.HCFA1500 TO OPTIM
/
GRANT SELECT ON PROD.IDENTIFICATION_NUMBER TO OPTIM
/
GRANT SELECT ON PROD.INDIVIDUAL_INFORMATION TO OPTIM
/
GRANT SELECT ON PROD.INSURANCE_INFORMATION TO OPTIM
/
GRANT SELECT ON PROD.LICENSE_NUMBER TO OPTIM
/
GRANT SELECT ON PROD.MEMBER_LINK TO OPTIM
/
GRANT SELECT ON PROD.MEMBER_PHYSICAL_ADDRESS TO OPTIM
/
GRANT SELECT ON PROD.ORGANIZATION_INFORMATION TO OPTIM
/
GRANT SELECT ON PROD.OTHER_ORGANIZATION_NAME_USED TO OPTIM
/
GRANT SELECT ON PROD.PATIENT_INFO TO OPTIM
/
GRANT SELECT ON PROD.PER_MEMBER_PER_MONTH_BILL_LINE TO OPTIM
/
GRANT SELECT ON PROD.PERSON_NAME TO OPTIM
/
GRANT SELECT ON PROD.POSTAL_ADDRESS TO OPTIM
/
GRANT SELECT ON PROD.RBRVS_DETAILS TO OPTIM
/
GRANT SELECT ON PROD.TAX_ENTITY TO OPTIM
/
GRANT SELECT ON PROD.TELEPHONE TO OPTIM
/
GRANT SELECT ON PROD.UB92 TO OPTIM
/
GRANT SELECT ON PROD.ZIP_TO_CARRIER_LOCALITY TO OPTIM
/
GRANT SELECT ON PROD.CLAIM_SEARCH_INPUT TO OPTIM
/
GRANT SELECT ON PROD.CONSOLIDATED_CLAIM TO OPTIM
/
GRANT SELECT ON PROD.CONVERTED_SUPPLIER_INVOICE TO OPTIM
/
GRANT SELECT ON PROD.MEMBER_TYPE_INFO TO OPTIM
/
GRANT SELECT ON PROD.SUBSCRIPTION TO OPTIM
/
GRANT SELECT ON PROD.SUBSCRIPTION_SELECTION TO OPTIM
/
GRANT UPDATE ON PROD.ABSTRACT_EOB_ATTACHMENT TO OPTIM
/
GRANT UPDATE ON PROD.ZIP_TO_CARRIER_LOCALITY TO OPTIM
/
GRANT UPDATE ON PROD.BANK_ACCOUNT TO OPTIM
/
GRANT UPDATE ON PROD.CORRESPONDENCE_INFORMATION TO OPTIM
/
GRANT UPDATE ON PROD.DENTAL_SUPPLIER_INVOICE TO OPTIM
/
GRANT UPDATE ON PROD.HCFA1500 TO OPTIM
/
GRANT UPDATE ON PROD.IDENTIFICATION_NUMBER TO OPTIM
/
GRANT UPDATE ON PROD.INDIVIDUAL_INFORMATION TO OPTIM
/
GRANT UPDATE ON PROD.INSURANCE_INFORMATION TO OPTIM
/
GRANT UPDATE ON PROD.LICENSE_NUMBER TO OPTIM
/
GRANT UPDATE ON PROD.MEMBER_LINK TO OPTIM
/
GRANT UPDATE ON PROD.MEMBER_PHYSICAL_ADDRESS TO OPTIM
/
GRANT UPDATE ON PROD.ORGANIZATION_INFORMATION TO OPTIM
/
GRANT UPDATE ON PROD.OTHER_ORGANIZATION_NAME_USED TO OPTIM
/
GRANT UPDATE ON PROD.PATIENT_INFO TO OPTIM
/
GRANT UPDATE ON PROD.PER_MEMBER_PER_MONTH_BILL_LINE TO OPTIM
/
GRANT UPDATE ON PROD.PERSON_NAME TO OPTIM
/
GRANT UPDATE ON PROD.POSTAL_ADDRESS TO OPTIM
/
GRANT UPDATE ON PROD.RBRVS_DETAILS TO OPTIM
/
GRANT UPDATE ON PROD.TAX_ENTITY TO OPTIM
/
GRANT UPDATE ON PROD.TELEPHONE TO OPTIM
/
GRANT UPDATE ON PROD.UB92 TO OPTIM
/
GRANT UPDATE ON PROD.ADDRESS_INFORMATION TO OPTIM
/
GRANT UPDATE ON PROD.CLAIM_SEARCH_INPUT TO OPTIM
/
GRANT UPDATE ON PROD.CONSOLIDATED_CLAIM TO OPTIM
/
GRANT UPDATE ON PROD.CONVERTED_SUPPLIER_INVOICE TO OPTIM
/
GRANT UPDATE ON PROD.MEMBER_TYPE_INFO TO OPTIM
/
GRANT UPDATE ON PROD.SUBSCRIPTION TO OPTIM
/
GRANT UPDATE ON PROD.SUBSCRIPTION_SELECTION TO OPTIM
/
GRANT SELECT ON PROD.COB_POLICY TO OPTIM
/
GRANT INSERT ON PROD.COB_POLICY TO OPTIM
/
GRANT UPDATE ON PROD.COB_POLICY TO OPTIM
/
GRANT DELETE ON PROD.COB_POLICY TO OPTIM
/
GRANT CREATE PROCEDURE TO OPTIM
/
GRANT CREATE SESSION TO OPTIM
/
GRANT CREATE TABLE TO OPTIM
/
GRANT CREATE VIEW TO OPTIM
/
GRANT SELECT ANY DICTIONARY TO OPTIM
/

spool off;

exit;


