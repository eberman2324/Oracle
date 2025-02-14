

Role Name: kill_user_sessions

Description:  This role will kill all user sessions for non oracle managed accounts and user accounts  not granted role INDESTRUCTIBLE_USERS_DURING_DEVOPS_IMPLEMENTATIONS.

Inputs: instance_name       Mandatory.   The ORACLE_SID of the non-pluggable or container database for which user sessions are being killed.
        pdb_name            Mandatory for pluggable databases.   The name of pluggable database for which user sessions are being killed.
