-- -------------------------------------------------
-- /sys/acls/adauthctn.xml
-- -------------------------------------------------

BEGIN
  DBMS_NETWORK_ACL_ADMIN.create_acl (
    acl          => '/sys/acls/adauthctn.xml',
    description  => '/sys/acls/adauthctn.xml',
    principal    => 'AEDBA',
    is_grant     => true,
    privilege    => 'connect',
    start_date   => NULL,
    end_date     => NULL);
  COMMIT;
END;
/

BEGIN
  DBMS_NETWORK_ACL_ADMIN.assign_acl (
    acl         => '/sys/acls/adauthctn.xml',
    host        => '10.6.74.35',
    lower_port  => 389,
    upper_port  => 389);
  COMMIT;
END;
/

BEGIN
  DBMS_NETWORK_ACL_ADMIN.add_privilege (
    acl       => '/sys/acls/adauthctn.xml',
    principal => 'AEDBA',
    is_grant  => true,
    privilege => 'resolve',
    start_date   => NULL,
    end_date     => NULL);
  COMMIT;
END;
/

BEGIN
  DBMS_NETWORK_ACL_ADMIN.add_privilege (
    acl       => '/sys/acls/adauthctn.xml',
    principal => 'AEDBA',
    is_grant  => true,
    privilege => 'connect',
    start_date   => NULL,
    end_date     => NULL);
  COMMIT;
END;
/

BEGIN
  DBMS_NETWORK_ACL_ADMIN.assign_acl (
    acl         => '/sys/acls/adauthctn.xml',
    host        => 'adldap.aeth.aetna.com',
    lower_port  => 389,
    upper_port  => 389);
  COMMIT;
END;
/

BEGIN
  DBMS_NETWORK_ACL_ADMIN.add_privilege (
    acl       => '/sys/acls/adauthctn.xml',
    principal => 'AEDBA',
    is_grant  => true,
    privilege => 'resolve',
    start_date   => NULL,
    end_date     => NULL);
  COMMIT;
END;
/

BEGIN
  DBMS_NETWORK_ACL_ADMIN.add_privilege (
    acl       => '/sys/acls/adauthctn.xml',
    principal => 'AEDBA',
    is_grant  => true,
    privilege => 'connect',
    start_date   => NULL,
    end_date     => NULL);
  COMMIT;
END;
/

BEGIN
  DBMS_NETWORK_ACL_ADMIN.assign_acl (
    acl         => '/sys/acls/adauthctn.xml',
    host        => 'azph-srv-dc01.cvty.com',
    lower_port  => 389,
    upper_port  => 389);
  COMMIT;
END;
/

BEGIN
  DBMS_NETWORK_ACL_ADMIN.add_privilege (
    acl       => '/sys/acls/adauthctn.xml',
    principal => 'AEDBA',
    is_grant  => true,
    privilege => 'resolve',
    start_date   => NULL,
    end_date     => NULL);
  COMMIT;
END;
/

BEGIN
  DBMS_NETWORK_ACL_ADMIN.add_privilege (
    acl       => '/sys/acls/adauthctn.xml',
    principal => 'AEDBA',
    is_grant  => true,
    privilege => 'connect',
    start_date   => NULL,
    end_date     => NULL);
  COMMIT;
END;
/

BEGIN
  DBMS_NETWORK_ACL_ADMIN.assign_acl (
    acl         => '/sys/acls/adauthctn.xml',
    host        => 'azph-srv-dc13.cvty.com',
    lower_port  => 389,
    upper_port  => 389);
  COMMIT;
END;
/

BEGIN
  DBMS_NETWORK_ACL_ADMIN.add_privilege (
    acl       => '/sys/acls/adauthctn.xml',
    principal => 'AEDBA',
    is_grant  => true,
    privilege => 'resolve',
    start_date   => NULL,
    end_date     => NULL);
  COMMIT;
END;
/

BEGIN
  DBMS_NETWORK_ACL_ADMIN.add_privilege (
    acl       => '/sys/acls/adauthctn.xml',
    principal => 'AEDBA',
    is_grant  => true,
    privilege => 'connect',
    start_date   => NULL,
    end_date     => NULL);
  COMMIT;
END;
/

BEGIN
  DBMS_NETWORK_ACL_ADMIN.assign_acl (
    acl         => '/sys/acls/adauthctn.xml',
    host        => 'msldap-east.corp.cvscaremark.com',
    lower_port  => 389,
    upper_port  => 389);
  COMMIT;
END;
/

BEGIN
  DBMS_NETWORK_ACL_ADMIN.add_privilege (
    acl       => '/sys/acls/adauthctn.xml',
    principal => 'AEDBA',
    is_grant  => true,
    privilege => 'resolve',
    start_date   => NULL,
    end_date     => NULL);
  COMMIT;
END;
/

BEGIN
  DBMS_NETWORK_ACL_ADMIN.add_privilege (
    acl       => '/sys/acls/adauthctn.xml',
    principal => 'AEDBA',
    is_grant  => true,
    privilege => 'connect',
    start_date   => NULL,
    end_date     => NULL);
  COMMIT;
END;
/

BEGIN
  DBMS_NETWORK_ACL_ADMIN.assign_acl (
    acl         => '/sys/acls/adauthctn.xml',
    host        => 'msldap.caremarkrx.net',
    lower_port  => 389,
    upper_port  => 389);
  COMMIT;
END;
/

BEGIN
  DBMS_NETWORK_ACL_ADMIN.add_privilege (
    acl       => '/sys/acls/adauthctn.xml',
    principal => 'AEDBA',
    is_grant  => true,
    privilege => 'resolve',
    start_date   => NULL,
    end_date     => NULL);
  COMMIT;
END;
/

BEGIN
  DBMS_NETWORK_ACL_ADMIN.add_privilege (
    acl       => '/sys/acls/adauthctn.xml',
    principal => 'AEDBA',
    is_grant  => true,
    privilege => 'connect',
    start_date   => NULL,
    end_date     => NULL);
  COMMIT;
END;
/

BEGIN
  DBMS_NETWORK_ACL_ADMIN.assign_acl (
    acl         => '/sys/acls/adauthctn.xml',
    host        => 'msldap.corp.cvs.com',
    lower_port  => 389,
    upper_port  => 389);
  COMMIT;
END;
/

BEGIN
  DBMS_NETWORK_ACL_ADMIN.add_privilege (
    acl       => '/sys/acls/adauthctn.xml',
    principal => 'AEDBA',
    is_grant  => true,
    privilege => 'resolve',
    start_date   => NULL,
    end_date     => NULL);
  COMMIT;
END;
/

