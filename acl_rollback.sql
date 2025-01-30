BEGIN
  DBMS_NETWORK_ACL_ADMIN.drop_acl (
    acl          => '/sys/acls/adauthctn.xml');
  COMMIT;
END;
/
