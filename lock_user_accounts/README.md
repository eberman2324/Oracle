

Role Name: lock_user_accounts

Description:  This role will lock all user accounts in an oracle database that are not oracle managaned and are not granted role USERS_TO_REMAIN_UNLOCKED_DURING_DEVOPS_IMPLEMENTATIONS.

Inputs: instance_name       Mandatory.   The ORACLE_SID of the non-pluggable or container database for which user accounts are being locked.
        pdb_name            Mandatory for pluggable databases.   The name of pluggable database for which user accounts are being locked.
