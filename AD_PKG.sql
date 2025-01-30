CREATE OR REPLACE EDITIONABLE PACKAGE AEDBA.AD_PKG  as 
/******************************************************************************/
/* Modification History                                                       */
/*                                                                            */
/* PACKAGE  : LDAP_PKG                                                        */
/* CREATED  : July 17th 2014                                                  */
/* BY       : Peter Pastore                                                   */
/*                                                                            */
/* PURPOSE  : This package is used to communicate with LDAP for Oracle        */
/*            connection entries.                                             */
/*                                                                            */
/* -------------------------------------------------------------------------- */
/* Date       | By          | Reason                                          */
/* 07/17/2014 | P. Pastore  | First Write                                     */
/* 01/25/2019 | P. Pastore  | Added AETH Domain                               */
/* 09/09/2019 | P. Pastore  | Added CORP Domain                               */
/* 10/23/2019 | P. Pastore  | Added CVS Domain                                */
/* 12/02/2019 | P. Pastore  | Added CAREMARKRX Domain                         */
/* 01/10/2023 | P. Pastore  | Copied from ICRPRD to HEPYDEV                   */
/******************************************************************************/

    /**********************************/
    /* Global Variables and Constants */
    /**********************************/
    lf_gc       constant varchar2(100)  := chr(13)||chr(10);  
    tab_gc      constant varchar2(7)    := chr(9);
    pkg_name_gc constant varchar2(50)   := 'ad_pkg';
    /*******************************************/
    /* Builds an a Type of Table               */
    /* Usage Example                           */
    /* select                                  */
    /*     attribute_name,                     */
    /*     attribute_value                     */
    /* from                                    */
    /*     table (AEDBA.ad_pkg.cvty('A603481')); */
    /*******************************************/
    function cvty 
    ( 
        emp_id_ip varchar2
    )  return AEDBA.ad_user_ct pipelined;


    function aeth 
    ( 
        emp_id_ip varchar2
    )  return AEDBA.ad_user_ct pipelined;
    
    function caremarkrx
    (
        emp_id_ip      varchar2,
        search_type_ip char, -- E = Employee ID, S = sAMAccountName
        file_ip        utl_file.file_type default null,    
        debug_ip       char default 'N'
    )return AEDBA.ad_user_ct pipelined;

    function corp
    (
        emp_id_ip      varchar2,
        search_type_ip char, -- E = Employee ID, S = sAMAccountName
        file_ip        utl_file.file_type default null,    
        debug_ip       char default 'N'
    )return AEDBA.ad_user_ct pipelined;
    
    function cvs
    (
        emp_id_ip      varchar2, 
        search_type_ip char, -- E = Employee ID, S = sAMAccountName
        file_ip        utl_file.file_type default null,    
        debug_ip       char default 'N'
    )return AEDBA.ad_user_ct pipelined;

END AD_PKG;
/
CREATE OR REPLACE EDITIONABLE PACKAGE BODY AEDBA.AD_PKG as
/******************************************************************************/
/* Modification History                                                       */
/*                                                                            */
/* PACKAGE  : LDAP_PKG                                                        */
/* CREATED  : July 17th 2014                                                  */
/* BY       : Peter Pastore                                                   */
/*                                                                            */
/* PURPOSE  : This package is used to communicate with LDAP for Oracle        */
/*            connection entries.                                             */
/*                                                                            */
/* -------------------------------------------------------------------------- */
/* Date       | By          | Reason                                          */
/* 07/17/2014 | P. Pastore  | First Write                                     */
/* 01/25/2019 | P. Pastore  | Added AETH Domain                               */
/* 09/09/2019 | P. Pastore  | Added CORP Domain                               */
/* 10/23/2019 | P. Pastore  | Added CVS Domain                                */
/* 12/02/2019 | P. Pastore  | Added CAREMARKRX Domain                         */
/* 01/10/2023 | P. Pastore  | Copied from ICRPRD to HEPYDEV                   */
/******************************************************************************/

/******************************************************************************/
/* Function ------------------------------------------------------------------*/
/******************************************************************************/
function cvty 
( 
    emp_id_ip varchar2
)  
return AEDBA.ad_user_ct pipelined as
    /***************/
    /* LDAP Values */
    /***************/
    host_lv         varchar2(256);
    port_lv         varchar2(256);
    auth_acct_lv    varchar2(256);
    pw_lv           varchar2(256);
    base_dn_lv      varchar2(256);

    /**************************************/
    /* Error Handling Constants/Variables */
    /**************************************/
    err_msg_lv          varchar2(4000);
    err_num_lv          number;    
    err_pnt_lv          number;

    /***********************/
    /* DBMS_LDAP variables */
    /***********************/
    atttrib_lv      dbms_ldap.string_collection;
    ber_element_lv  dbms_ldap.ber_element;
    entry_lv        dbms_ldap.message;
    msg_lv          dbms_ldap.message; 
    session_id_lv   dbms_ldap.session;
    vals_lv         dbms_ldap.string_collection ;
    
    /*******************/
    /* Local Variables */
    /*******************/
    attrib_idx_lv       pls_integer;
    attrib_nm_lv        varchar2(256);
    dn_lv               varchar2(256);
    end_lv              pls_integer;
    entry_idx_lv        pls_integer;
    ldap_mstr_id_lv     number(11) default 1; 
    node_parent_lv      clob;
    old_nc_lv           varchar2(1000);
    result_lv           pls_integer;
    retval_lv           pls_integer;
    split_string_lv     varchar2(32767);
    xml_lv              clob;
    /********************/
    /* Output Variables */
    /********************/
    oranet_op       varchar2(32767);
    sid_op          varchar2(50);
    
    /**************/
    /* Exceptions */
    /**************/
    ldap_failed  exception;
BEGIN
    err_pnt_lv  := 10;
    retval_lv   := -1;
    
    select 
        a1.config_val,
        a2.config_val,
        a3.config_val,
        a4.config_val,
        a5.config_val
    into
        host_lv,
        port_lv,
        auth_acct_lv,
        pw_lv,
        base_dn_lv
    from 
        ad_config a1,
        ad_config a2, 
        ad_config a3, 
        ad_config a4, 
        ad_config a5 
    where 
        a1.config_var = 'ADCVTYHOST'
    and a2.config_var = 'ADCVTYPORT'
    and a3.config_var = 'ADCVTYAUTH'
    and a4.config_var = 'ADCVTYPW'
    and a5.config_var = 'ADCVTYBASE';    

    /**********************************************************/
    /* Choosing exceptions to be raised by DBMS_LDAP library. */
    /**********************************************************/
    err_pnt_lv              := 20;
    dbms_ldap.use_exception := true;

    /************************/
    /* Get a session Handle */
    /************************/
    err_pnt_lv      := 30;    
    session_id_lv   := dbms_ldap.init(host_lv, port_lv);
    
    /***********************************************************/
    /* Establish Connection to LDAP server                     */ 
    /***********************************************************/
    err_pnt_lv  := 40;   
    result_lv   := dbms_ldap.simple_bind_s
                ( 
                    session_id_lv, 
                    auth_acct_lv, 
                    pw_lv 
                );

    if (result_lv != 0) 
    then 
        raise ldap_failed;
    end if;

    /**************************************************/
    /* Now do the LDAP search For All Entries         */
    /**************************************************/
    err_pnt_lv      := 50;   
    atttrib_lv(1)   := '*'; -- retrieve all attributes 
    
    retval_lv := dbms_ldap.search_s
                    (
                        session_id_lv, 
                        base_dn_lv, 
                        dbms_ldap.scope_subtree,
                        '(&(objectclass=top)(employeeid=' || emp_id_ip || '))',
                        --'(&(objectclass=top)(cn=' || emp_id_ip || '))',                        
                        atttrib_lv,
                        0,
                        msg_lv);
                        
    /****************************************/    
    /* count the number of entries returned */
    /****************************************/
    err_pnt_lv  := 60; 
    retval_lv   := dbms_ldap.count_entries(session_id_lv, msg_lv);
    
    /***********************/
    /* get the first entry */
    /***********************/
    err_pnt_lv      := 70;     
    entry_lv        := dbms_ldap.first_entry(session_id_lv, msg_lv);
    entry_idx_lv    := 1;

    /***********************************************/
    /* Loop through each of the entries one by one */
    /***********************************************/
    err_pnt_lv      := 80;
    while entry_lv is not null 
    loop
        /***************************/
        /* print the current entry */
        /***************************/
        err_pnt_lv  := 90;
        dn_lv       := dbms_ldap.get_dn(session_id_lv, entry_lv);
        
        /*****************/
        /* Get Attribute */
        /*****************/
        err_pnt_lv      := 100;
        dbms_ldap.utf8_conversion := false; 
        
        attrib_nm_lv    := dbms_ldap.first_attribute
                            (
                                session_id_lv,
                                entry_lv, 
                                ber_element_lv
                            );
        attrib_idx_lv := 1;
        
        /*************************************************/
        /* Loop through the attribute and get the values */
        /*************************************************/
        err_pnt_lv      := 110;
        while attrib_nm_lv is not null 
        loop
            err_pnt_lv  := 120;
            vals_lv     := dbms_ldap.get_values 
                            (
                                session_id_lv, 
                                entry_lv,
                                attrib_nm_lv
                            );
                            
            if vals_lv.count > 0 
            then
            
                /*******************************************/
                /* More than 1 value so loop through these */
                /*******************************************/
                for i in vals_lv.first..vals_lv.last 
                loop
                    err_pnt_lv  := 130;
                    /**********************************************************/
                    /* data for piped results.                                */
                    /* this is what gets sent back to the user                */
                    /**********************************************************/
                    --dbms_output.put_line('attibute_name: ' || attrib_nm_lv || ' = ' || substr(vals_lv(i),1,200));

                    pipe row
                    (
                        ad_user_t
                        (attribute_name => attrib_nm_lv,
                            attribute_value => substr(vals_lv(i),1,200)
                        )
                    );
                end loop; -- FOR i in vals_lv.FIRST..vals_lv.LAST
            end if; -- if vals_lv.COUNT > 0 
            /***************************************/
            /* Get the next Attribute for the loop */
            /***************************************/
            err_pnt_lv  := 140;

            attrib_nm_lv := dbms_ldap.next_attribute
                                (
                                    session_id_lv,
                                    entry_lv,
                                    ber_element_lv
                                );
                                
            attrib_idx_lv := attrib_idx_lv+1;
            
        end loop; -- while attrib_nm_lv IS NOT NULL 
                
        /*********************************/
        /* Pipe the data out to the type */
        /*********************************/
        /*****************/
        /* Get the entry */
        /*****************/
        err_pnt_lv      := 150;
        entry_lv        := dbms_ldap.next_entry(session_id_lv, entry_lv);
        entry_idx_lv    := entry_idx_lv+1;

    end loop; -- while entry_lv IS NOT NULL 

    /* Second Search --------------*/
    retval_lv := dbms_ldap.search_s
                    (
                        session_id_lv, 
                        base_dn_lv, 
                        dbms_ldap.scope_subtree,
                        --'(&(objectclass=top)(employeeid=' || emp_id_ip || '))',
                        '(&(objectclass=top)(cn=' || emp_id_ip || '))',                        
                        atttrib_lv,
                        0,
                        msg_lv);
                        
    /****************************************/    
    /* count the number of entries returned */
    /****************************************/
    err_pnt_lv  := 160; 
    retval_lv   := dbms_ldap.count_entries(session_id_lv, msg_lv);
    
    /***********************/
    /* get the first entry */
    /***********************/
    err_pnt_lv      := 170;     
    entry_lv        := dbms_ldap.first_entry(session_id_lv, msg_lv);
    entry_idx_lv    := 1;

    /***********************************************/
    /* Loop through each of the entries one by one */
    /***********************************************/
    err_pnt_lv      := 180;
    while entry_lv is not null 
    loop
        /***************************/
        /* Print the current entry */
        /***************************/
        err_pnt_lv  := 190;
        dn_lv       := dbms_ldap.get_dn(session_id_lv, entry_lv);
        
        /*****************/
        /* Get Attribute */
        /*****************/
        err_pnt_lv      := 200;
        dbms_ldap.utf8_conversion := false; 
        
        attrib_nm_lv    := dbms_ldap.first_attribute
                            (
                                session_id_lv,
                                entry_lv, 
                                ber_element_lv
                            );
        attrib_idx_lv := 1;
        
        /*************************************************/
        /* Loop through the attribute and get the values */
        /*************************************************/
        err_pnt_lv      := 210;
        while attrib_nm_lv is not null 
        loop
            err_pnt_lv  := 220;
            vals_lv     := dbms_ldap.get_values 
                            (
                                session_id_lv, 
                                entry_lv,
                                attrib_nm_lv
                            );
                            
            if vals_lv.count > 0 
            then
            
                /*******************************************/
                /* More than 1 value so loop through these */
                /*******************************************/
                for i in vals_lv.first..vals_lv.last 
                loop
                    err_pnt_lv  := 230;
                    /**********************************************************/
                    /* Data for Piped results.                                */
                    /* This is what gets sent back to the user                */
                    /**********************************************************/
                    --DBMS_OUTPUT.PUT_LINE('ATTIBUTE_NAME: ' || attrib_nm_lv || ' = ' || SUBSTR(vals_lv(i),1,200));

                    pipe row
                    (
                        ad_user_t
                        (attribute_name => attrib_nm_lv,
                            attribute_value => substr(vals_lv(i),1,200)
                        )
                    );
                end loop; -- FOR i in vals_lv.FIRST..vals_lv.LAST
            end if; -- if vals_lv.COUNT > 0 
            /***************************************/
            /* Get the next Attribute for the loop */
            /***************************************/
            err_pnt_lv  := 240;

            attrib_nm_lv := dbms_ldap.next_attribute
                                (
                                    session_id_lv,
                                    entry_lv,
                                    ber_element_lv
                                );
                                
            attrib_idx_lv := attrib_idx_lv+1;
            
        end loop; -- while attrib_nm_lv IS NOT NULL 
                
        /*********************************/
        /* Pipe the data out to the type */
        /*********************************/
        /*****************/
        /* Get the entry */
        /*****************/
        err_pnt_lv      := 250;
        entry_lv        := dbms_ldap.next_entry(session_id_lv, entry_lv);
        entry_idx_lv    := entry_idx_lv+1;

    end loop; -- while entry_lv IS NOT NULL 
    /********************/    
    /* End LDAP Session */
    /********************/
    err_pnt_lv  := 260;
    end_lv      := dbms_ldap.unbind_s (session_id_lv);
    
    return;
exception
    when no_data_needed     
    then
        dbms_output.put_line ( '***>>> CLEAN UP' );
        return;
    when ldap_failed
    then
        err_msg_lv  := 'DB-FUNCTION ERROR. AEDBA.CVTY'
                    || ' Unhandled AD Error.';

        err_num_lv := -20099;
        
        raise_application_error (err_num_lv, err_pnt_lv || ' ' || err_msg_lv);
        
    when dbms_ldap.general_error 
    then
        err_msg_lv  := 'DB-FUNCTION ERROR. AEDBA.CVTY'
                    || ' DBMS_LDAP.GENERAL_ERROR.'
                    || sqlerrm;

        err_num_lv := -20099;
        
        raise_application_error (err_num_lv, err_pnt_lv || ' ' || err_msg_lv); 
 
    when others then
        err_msg_lv  := 'DB-FUNCTION ERROR. AEDBA.CVTY'
                    || ' OTHER ERROR.'
                    || sqlerrm;

        err_num_lv := -20099;
        
        raise_application_error (err_num_lv, err_pnt_lv || ' ' || err_msg_lv);         

    
end cvty;
/******************************************************************************/
/* Function ------------------------------------------------------------------*/
/******************************************************************************/
function aeth 
( 
    emp_id_ip varchar2
)  
return AEDBA.ad_user_ct pipelined as
    /***************/
    /* LDAP Values */
    /***************/
    host_lv         varchar2(256);
    port_lv         varchar2(256);
    auth_acct_lv    varchar2(256);
    pw_lv           varchar2(256);
    base_dn_lv      varchar2(256);

    /**************************************/
    /* Error Handling Constants/Variables */
    /**************************************/
    err_msg_lv          varchar2(4000);
    err_num_lv          number;    
    err_pnt_lv          number;

    /***********************/
    /* DBMS_LDAP variables */
    /***********************/
    atttrib_lv      dbms_ldap.string_collection;
    ber_element_lv  dbms_ldap.ber_element;
    entry_lv        dbms_ldap.message;
    msg_lv          dbms_ldap.message; 
    session_id_lv   dbms_ldap.session;
    vals_lv         dbms_ldap.string_collection ;
    
    /*******************/
    /* Local Variables */
    /*******************/
    attrib_idx_lv       pls_integer;
    attrib_nm_lv        varchar2(256);
    dn_lv               varchar2(256);
    end_lv              pls_integer;
    entry_idx_lv        pls_integer;
    ldap_mstr_id_lv     number(11) default 1; 
    node_parent_lv      clob;
    old_nc_lv           varchar2(1000);
    result_lv           pls_integer;
    retval_lv           pls_integer;
    split_string_lv     varchar2(32767);
    xml_lv              clob;
    /********************/
    /* Output Variables */
    /********************/
    oranet_op       varchar2(32767);
    sid_op          varchar2(50);
    
    /**************/
    /* Exceptions */
    /**************/
    ldap_failed  exception;
BEGIN
    err_pnt_lv  := 270;
    retval_lv   := -1;
    
    select 
        a1.config_val,
        a2.config_val,
        a3.config_val,
        a4.config_val,
        a5.config_val
    into
        host_lv,
        port_lv,
        auth_acct_lv,
        pw_lv,
        base_dn_lv
    from 
        ad_config a1,
        ad_config a2, 
        ad_config a3, 
        ad_config a4, 
        ad_config a5 
    where 
        a1.config_var = 'ADAETHHOST'
    and a2.config_var = 'ADAETHPORT'
    and a3.config_var = 'ADAETHAUTH'
    and a4.config_var = 'ADAETHPW'
    and a5.config_var = 'ADAETHBASE';    

    /**********************************************************/
    /* Choosing exceptions to be raised by DBMS_LDAP library. */
    /**********************************************************/
    err_pnt_lv              := 280;
    dbms_ldap.use_exception := true;

    /************************/
    /* Get a session Handle */
    /************************/
    err_pnt_lv      := 290;    
    session_id_lv   := dbms_ldap.init(host_lv, port_lv);
    
    /***********************************************************/
    /* Establish Connection to LDAP server                     */ 
    /***********************************************************/
    err_pnt_lv  := 300;   
    result_lv   := dbms_ldap.simple_bind_s
                ( 
                    session_id_lv, 
                    auth_acct_lv, 
                    pw_lv 
                );

    if (result_lv != 0) 
    then 
        raise ldap_failed;
    end if;

    /**************************************************/
    /* Now do the LDAP search For All Entries         */
    /**************************************************/
    err_pnt_lv      := 310;   
    atttrib_lv(1)   := '*'; -- retrieve all attributes 
    
    retval_lv := dbms_ldap.search_s
                    (
                        session_id_lv, 
                        base_dn_lv, 
                        dbms_ldap.scope_subtree,
                        '(&(objectclass=top)(sAMAccountName=' || emp_id_ip || '))',
                        --'(&(objectclass=top)(employeeid=' || emp_id_ip || '))',
                        --'(&(objectclass=top)(cn=' || emp_id_ip || '))',                        
                        atttrib_lv,
                        0,
                        msg_lv);
                        
    /****************************************/    
    /* count the number of entries returned */
    /****************************************/
    err_pnt_lv  := 320; 
    retval_lv   := dbms_ldap.count_entries(session_id_lv, msg_lv);
    
    /***********************/
    /* get the first entry */
    /***********************/
    err_pnt_lv      := 330;     
    entry_lv        := dbms_ldap.first_entry(session_id_lv, msg_lv);
    entry_idx_lv    := 1;

    /***********************************************/
    /* Loop through each of the entries one by one */
    /***********************************************/
    err_pnt_lv      := 340;
    while entry_lv is not null 
    loop
        /***************************/
        /* print the current entry */
        /***************************/
        err_pnt_lv  := 350;
        dn_lv       := dbms_ldap.get_dn(session_id_lv, entry_lv);
        
        /*****************/
        /* Get Attribute */
        /*****************/
        err_pnt_lv      := 360;
        dbms_ldap.utf8_conversion := false; 
        
        attrib_nm_lv    := dbms_ldap.first_attribute
                            (
                                session_id_lv,
                                entry_lv, 
                                ber_element_lv
                            );
        attrib_idx_lv := 1;
        
        /*************************************************/
        /* Loop through the attribute and get the values */
        /*************************************************/
        err_pnt_lv      := 370;
        while attrib_nm_lv is not null 
        loop
            err_pnt_lv  := 380;
            vals_lv     := dbms_ldap.get_values 
                            (
                                session_id_lv, 
                                entry_lv,
                                attrib_nm_lv
                            );
                            
            if vals_lv.count > 0 
            then
            
                /*******************************************/
                /* More than 1 value so loop through these */
                /*******************************************/
                for i in vals_lv.first..vals_lv.last 
                loop
                    err_pnt_lv  := 390;
                    /**********************************************************/
                    /* data for piped results.                                */
                    /* this is what gets sent back to the user                */
                    /**********************************************************/
                    --dbms_output.put_line('attibute_name: ' || attrib_nm_lv || ' = ' || substr(vals_lv(i),1,200));

                    pipe row
                    (
                        ad_user_t
                        (attribute_name => attrib_nm_lv,
                            attribute_value => substr(vals_lv(i),1,200)
                        )
                    );
                end loop; -- FOR i in vals_lv.FIRST..vals_lv.LAST
            end if; -- if vals_lv.COUNT > 0 
            /***************************************/
            /* Get the next Attribute for the loop */
            /***************************************/
            err_pnt_lv  := 400;

            attrib_nm_lv := dbms_ldap.next_attribute
                                (
                                    session_id_lv,
                                    entry_lv,
                                    ber_element_lv
                                );
                                
            attrib_idx_lv := attrib_idx_lv+1;
            
        end loop; -- while attrib_nm_lv IS NOT NULL 
                
        /*********************************/
        /* Pipe the data out to the type */
        /*********************************/
        /*****************/
        /* Get the entry */
        /*****************/
        err_pnt_lv      := 410;
        entry_lv        := dbms_ldap.next_entry(session_id_lv, entry_lv);
        entry_idx_lv    := entry_idx_lv+1;

    end loop; -- while entry_lv IS NOT NULL 

    /* Second Search --------------*/
    retval_lv := dbms_ldap.search_s
                    (
                        session_id_lv, 
                        base_dn_lv, 
                        dbms_ldap.scope_subtree,
                        '(&(objectclass=top)(sAMAccountName=' || emp_id_ip || '))',
                        --'(&(objectclass=top)(employeeid=' || emp_id_ip || '))',
                        --'(&(objectclass=top)(cn=' || emp_id_ip || '))',                        
                        atttrib_lv,
                        0,
                        msg_lv);
                        
    /****************************************/    
    /* count the number of entries returned */
    /****************************************/
    err_pnt_lv  := 420; 
    retval_lv   := dbms_ldap.count_entries(session_id_lv, msg_lv);
    
    /***********************/
    /* get the first entry */
    /***********************/
    err_pnt_lv      := 430;     
    entry_lv        := dbms_ldap.first_entry(session_id_lv, msg_lv);
    entry_idx_lv    := 1;

    /***********************************************/
    /* Loop through each of the entries one by one */
    /***********************************************/
    err_pnt_lv      := 440;
    while entry_lv is not null 
    loop
        /***************************/
        /* Print the current entry */
        /***************************/
        err_pnt_lv  := 450;
        dn_lv       := dbms_ldap.get_dn(session_id_lv, entry_lv);
        
        /*****************/
        /* Get Attribute */
        /*****************/
        err_pnt_lv      := 460;
        dbms_ldap.utf8_conversion := false; 
        
        attrib_nm_lv    := dbms_ldap.first_attribute
                            (
                                session_id_lv,
                                entry_lv, 
                                ber_element_lv
                            );
        attrib_idx_lv := 1;
        
        /*************************************************/
        /* Loop through the attribute and get the values */
        /*************************************************/
        err_pnt_lv      := 470;
        while attrib_nm_lv is not null 
        loop
            err_pnt_lv  := 480;
            vals_lv     := dbms_ldap.get_values 
                            (
                                session_id_lv, 
                                entry_lv,
                                attrib_nm_lv
                            );
                            
            if vals_lv.count > 0 
            then
            
                /*******************************************/
                /* More than 1 value so loop through these */
                /*******************************************/
                for i in vals_lv.first..vals_lv.last 
                loop
                    err_pnt_lv  := 490;
                    /**********************************************************/
                    /* Data for Piped results.                                */
                    /* This is what gets sent back to the user                */
                    /**********************************************************/
                    --DBMS_OUTPUT.PUT_LINE('ATTIBUTE_NAME: ' || attrib_nm_lv || ' = ' || SUBSTR(vals_lv(i),1,200));

                    pipe row
                    (
                        ad_user_t
                        (attribute_name => attrib_nm_lv,
                            attribute_value => substr(vals_lv(i),1,200)
                        )
                    );
                end loop; -- FOR i in vals_lv.FIRST..vals_lv.LAST
            end if; -- if vals_lv.COUNT > 0 
            /***************************************/
            /* Get the next Attribute for the loop */
            /***************************************/
            err_pnt_lv  := 500;

            attrib_nm_lv := dbms_ldap.next_attribute
                                (
                                    session_id_lv,
                                    entry_lv,
                                    ber_element_lv
                                );
                                
            attrib_idx_lv := attrib_idx_lv+1;
            
        end loop; -- while attrib_nm_lv IS NOT NULL 
                
        /*********************************/
        /* Pipe the data out to the type */
        /*********************************/
        /*****************/
        /* Get the entry */
        /*****************/
        err_pnt_lv      := 510;
        entry_lv        := dbms_ldap.next_entry(session_id_lv, entry_lv);
        entry_idx_lv    := entry_idx_lv+1;

    end loop; -- while entry_lv IS NOT NULL 
    /********************/    
    /* End LDAP Session */
    /********************/
    err_pnt_lv  := 520;
    end_lv      := dbms_ldap.unbind_s (session_id_lv);
    
    return;
exception
    when no_data_needed     
    then
        dbms_output.put_line ( '***>>> CLEAN UP' );
        return;
    when ldap_failed
    then
        err_msg_lv  := 'DB-FUNCTION ERROR. AEDBA.AETH'
                    || ' Unhandled AD Error.';

        err_num_lv := -20099;
        
        raise_application_error (err_num_lv, err_pnt_lv || ' ' || err_msg_lv);
        
    when dbms_ldap.general_error 
    then
        err_msg_lv  := 'DB-FUNCTION ERROR. AEDBA.AETH'
                    || ' DBMS_LDAP.GENERAL_ERROR.'
                    || sqlerrm;

        err_num_lv := -20099;
        
        raise_application_error (err_num_lv, err_pnt_lv || ' ' || err_msg_lv); 
 
    when others then
        err_msg_lv  := 'DB-FUNCTION ERROR. AEDBA.AETH'
                    || ' OTHER ERROR.'
                    || sqlerrm;

        err_num_lv := -20099;
        
        raise_application_error (err_num_lv, err_pnt_lv || ' ' || err_msg_lv);         
end aeth;
/******************************************************************************/
/* Function ------------------------------------------------------------------*/
/******************************************************************************/
function caremarkrx 
( 
    emp_id_ip      varchar2,
    search_type_ip char, -- E = Employee ID, S = sAMAccountName
    file_ip        utl_file.file_type default null,    
    debug_ip       char default 'N'
)  
return AEDBA.ad_user_ct pipelined as
    /***************/
    /* LDAP Values */
    /***************/
    host_lv         varchar2(256);
    port_lv         varchar2(256);
    auth_acct_lv    varchar2(256);
    pw_lv           varchar2(256);
    base_dn_lv      varchar2(256);

    /**************************************/
    /* Error Handling Constants/Variables */
    /**************************************/
    proc_nm_lv          varchar2(50) := 'caremarkrx';
    err_msg_lv          varchar2(4000);
    err_num_lv          number;    
    err_pnt_lv          number;

    /***********************/
    /* DBMS_LDAP variables */
    /***********************/
    atttrib_lv      dbms_ldap.string_collection;
    ber_element_lv  dbms_ldap.ber_element;
    entry_lv        dbms_ldap.message;
    msg_lv          dbms_ldap.message; 
    session_id_lv   dbms_ldap.session;
    vals_lv         dbms_ldap.string_collection ;
    
    /*******************/
    /* Local Variables */
    /*******************/
    attrib_idx_lv       pls_integer;
    attrib_nm_lv        varchar2(256);
    dn_lv               varchar2(256);
    end_lv              pls_integer;
    entry_idx_lv        pls_integer;
    file_lv             utl_file.file_type;   
    file_is_open_lv     boolean default false;    
    ldap_mstr_id_lv     number(11) default 1; 
    node_parent_lv      clob;
    old_nc_lv           varchar2(1000);
    result_lv           pls_integer;
    retval_lv           pls_integer;
    search_str_lv       varchar2(4000);
    split_string_lv     varchar2(32767);
    xml_lv              clob;
    /********************/
    /* Output Variables */
    /********************/
    oranet_op       varchar2(32767);
    sid_op          varchar2(50);
    
    /**************/
    /* Exceptions */
    /**************/
    ldap_failed  exception;
BEGIN
    err_pnt_lv  := 530;
    retval_lv   := -1;

    if (debug_ip = 'Y')
    then
        file_is_open_lv := utl_file.is_open(file_ip);
        
        if (file_is_open_lv = false)
        then
            file_lv := utl_file.fopen('APEX_LOGS', pkg_name_gc || '_' || proc_nm_lv || '.log', 'A');
            utl_file.put_line(file_lv, rpad('-',80,'-'));
            utl_file.put_line(file_lv, 'Debug Mode ON for:' || pkg_name_gc || '_' || proc_nm_lv);
            utl_file.fflush(file_lv); -- Flush the contents
        else
            file_lv := file_ip;
            utl_file.put_line(file_lv, '....Sub Process Call: ' || pkg_name_gc || '_' || proc_nm_lv);
            utl_file.fflush(file_lv); -- Flush the contents
        end if;

        utl_file.put_line(file_lv, 'INPUT PARAMETERS............');       
        utl_file.put_line(file_lv, (rpad('emp_id_ip', 35, '.')|| '= ' || emp_id_ip));
        utl_file.put_line(file_lv, (rpad('search_type_ip',  35, '.')|| '= ' || search_type_ip));
        utl_file.fflush(file_lv); -- Flush the contents        
    end if;        

    /**************************/
    /* Get the AD Credentials */
    /**************************/
    if (debug_ip = 'Y')
    then
        utl_file.put_line(file_lv, '');        
        utl_file.put_line(file_lv, 'Fetching AD Credentials');        
        utl_file.fflush(file_lv); -- Flush the contents
    end if;
    
    err_pnt_lv  := 540;
    
    select 
        a1.config_val,
        a2.config_val,
        a3.config_val,
        a4.config_val,
        a5.config_val
    into
        host_lv,
        port_lv,
        auth_acct_lv,
        pw_lv,
        base_dn_lv
    from 
        ad_config a1,
        ad_config a2, 
        ad_config a3, 
        ad_config a4, 
        ad_config a5 
    where 
        a1.config_var = 'CVS_RX_AD_SVR'
    and a2.config_var = 'CVS_RX_AD_PORT'
    and a3.config_var = 'CVS_RX_AD_AUTH'
    and a4.config_var = 'CVS_RX_AD_PW'
    and a5.config_var = 'CVS_RX_AD_BASE';    

    /**********************************************************/
    /* Choosing exceptions to be raised by DBMS_LDAP library. */
    /**********************************************************/
    if (debug_ip = 'Y')
    then
        utl_file.put_line(file_lv, 'Setting exception options');        
        utl_file.fflush(file_lv); -- Flush the contents
    end if;
    
    err_pnt_lv              := 550;
    dbms_ldap.use_exception := true;

    /************************/
    /* Get a session Handle */
    /************************/
    if (debug_ip = 'Y')
    then
        utl_file.put_line(file_lv, 'Setting session handle');        
        utl_file.fflush(file_lv); -- Flush the contents
    end if;

    err_pnt_lv      := 560;    
    session_id_lv   := dbms_ldap.init(host_lv, port_lv);
    
    /***********************************************************/
    /* Establish Connection to LDAP server                     */ 
    /***********************************************************/
    if (debug_ip = 'Y')
    then
        utl_file.put_line(file_lv, 'Establishing AD connection');        
        utl_file.fflush(file_lv); -- Flush the contents
    end if;
    
    err_pnt_lv  := 570;   
    result_lv   := dbms_ldap.simple_bind_s
                ( 
                    session_id_lv, 
                    auth_acct_lv, 
                    pw_lv 
                );

    if (result_lv != 0) 
    then 
        if (debug_ip = 'Y')
        then
            utl_file.put_line(file_lv, '....Connection Failed');        
            utl_file.fflush(file_lv); -- Flush the contents
        end if;
    
        raise ldap_failed;
    end if;

    if (debug_ip = 'Y')
    then
        utl_file.put_line(file_lv, '....Connected');        
        utl_file.fflush(file_lv); -- Flush the contents
    end if;

    /**************************************************/
    /* Now do the LDAP search For All Entries         */
    /**************************************************/
    if (debug_ip = 'Y')
    then
        utl_file.put_line(file_lv, '....Starting Search');        
        utl_file.fflush(file_lv); -- Flush the contents
    end if;
    
    err_pnt_lv      := 580;   
    atttrib_lv(1)   := '*'; -- retrieve all attributes 
    
    
    if (search_type_ip = 'E')
    then
        search_str_lv := '(&(objectclass=top)(employeeid=' || emp_id_ip || '))';
    else
        search_str_lv := '(&(objectclass=top)(sAMAccountName=' || emp_id_ip || '))';
        --search_str_lv := '(&(objectclass=top)(mailnickname=' || emp_id_ip || '))';        
    end if;
    
    retval_lv := dbms_ldap.search_s
                    (
                        session_id_lv, 
                        base_dn_lv, 
                        dbms_ldap.scope_subtree,
                        search_str_lv,
                        --'(&(objectclass=top)(employeeid=' || emp_id_ip || '))',
                        --'(&(objectclass=top)(cn=' || emp_id_ip || '))',                             
                        --'(&(objectclass=top)(sAMAccountName=' || emp_id_ip || '))',
                        atttrib_lv,
                        0,
                        msg_lv);
                        
    /****************************************/    
    /* count the number of entries returned */
    /****************************************/
    err_pnt_lv  := 590; 
    retval_lv   := dbms_ldap.count_entries(session_id_lv, msg_lv);

    if (debug_ip = 'Y')
    then
        utl_file.put_line(file_lv, '....Entries: ' || retval_lv);        
        utl_file.fflush(file_lv); -- Flush the contents
    end if;
    
    /***********************/
    /* get the first entry */
    /***********************/
    err_pnt_lv      := 600;     
    entry_lv        := dbms_ldap.first_entry(session_id_lv, msg_lv);
    entry_idx_lv    := 1;

    /***********************************************/
    /* Loop through each of the entries one by one */
    /***********************************************/
    err_pnt_lv      := 610;
    while entry_lv is not null 
    loop
        /***************************/
        /* print the current entry */
        /***************************/
        err_pnt_lv  := 620;
        dn_lv       := dbms_ldap.get_dn(session_id_lv, entry_lv);
        
        /*****************/
        /* Get Attribute */
        /*****************/
        err_pnt_lv      := 630;
        dbms_ldap.utf8_conversion := false; 
        
        attrib_nm_lv    := dbms_ldap.first_attribute
                            (
                                session_id_lv,
                                entry_lv, 
                                ber_element_lv
                            );
        attrib_idx_lv := 1;
        
        /*************************************************/
        /* Loop through the attribute and get the values */
        /*************************************************/
        err_pnt_lv      := 640;
        while attrib_nm_lv is not null 
        loop
            err_pnt_lv  := 650;
            vals_lv     := dbms_ldap.get_values 
                            (
                                session_id_lv, 
                                entry_lv,
                                attrib_nm_lv
                            );
                            
            if vals_lv.count > 0 
            then
                /*******************************************/
                /* More than 1 value so loop through these */
                /*******************************************/
                for i in vals_lv.first..vals_lv.last 
                loop
                    err_pnt_lv  := 650;
                    /**********************************************************/
                    /* data for piped results.                                */
                    /* this is what gets sent back to the user                */
                    /**********************************************************/
                    /*
                    if (debug_ip = 'Y')
                    then
                        utl_file.put_line(file_lv, '......attibute_name: ' || attrib_nm_lv || ' = ' || substr(vals_lv(i),1,200));        
                        utl_file.fflush(file_lv); -- Flush the contents
                    end if;
                    */
                    
                    pipe row
                    (
                        ad_user_t
                        (attribute_name => attrib_nm_lv,
                            attribute_value => substr(vals_lv(i),1,200)
                        )
                    );
                end loop; -- FOR i in vals_lv.FIRST..vals_lv.LAST
            end if; -- if vals_lv.COUNT > 0 
            /***************************************/
            /* Get the next Attribute for the loop */
            /***************************************/
            err_pnt_lv  := 660;

            attrib_nm_lv := dbms_ldap.next_attribute
                                (
                                    session_id_lv,
                                    entry_lv,
                                    ber_element_lv
                                );
                                
            attrib_idx_lv := attrib_idx_lv+1;
            
        end loop; -- while attrib_nm_lv IS NOT NULL 
                
        /*********************************/
        /* Pipe the data out to the type */
        /*********************************/
        /*****************/
        /* Get the entry */
        /*****************/
        err_pnt_lv      := 670;
        entry_lv        := dbms_ldap.next_entry(session_id_lv, entry_lv);
        entry_idx_lv    := entry_idx_lv+1;

    end loop; -- while entry_lv IS NOT NULL 

    /* Second Search --------------*/
    retval_lv := dbms_ldap.search_s
                    (
                        session_id_lv, 
                        base_dn_lv, 
                        dbms_ldap.scope_subtree,
                        --'(&(objectclass=top)(employeeid=' || emp_id_ip || '))',
                        '(&(objectclass=top)(cn=' || emp_id_ip || '))',                        
                        atttrib_lv,
                        0,
                        msg_lv);
                        
    /****************************************/    
    /* count the number of entries returned */
    /****************************************/
    err_pnt_lv  := 680; 
    retval_lv   := dbms_ldap.count_entries(session_id_lv, msg_lv);
    
    /***********************/
    /* get the first entry */
    /***********************/
    err_pnt_lv      := 690;     
    entry_lv        := dbms_ldap.first_entry(session_id_lv, msg_lv);
    entry_idx_lv    := 1;

    /***********************************************/
    /* Loop through each of the entries one by one */
    /***********************************************/
    err_pnt_lv      := 700;
    while entry_lv is not null 
    loop
        /***************************/
        /* Print the current entry */
        /***************************/
        err_pnt_lv  := 710;
        dn_lv       := dbms_ldap.get_dn(session_id_lv, entry_lv);
        
        /*****************/
        /* Get Attribute */
        /*****************/
        err_pnt_lv      := 720;
        dbms_ldap.utf8_conversion := false; 
        
        attrib_nm_lv    := dbms_ldap.first_attribute
                            (
                                session_id_lv,
                                entry_lv, 
                                ber_element_lv
                            );
        attrib_idx_lv := 1;
        
        /*************************************************/
        /* Loop through the attribute and get the values */
        /*************************************************/
        err_pnt_lv      := 730;
        while attrib_nm_lv is not null 
        loop
            err_pnt_lv  := 740;
            vals_lv     := dbms_ldap.get_values 
                            (
                                session_id_lv, 
                                entry_lv,
                                attrib_nm_lv
                            );
                            
            if vals_lv.count > 0 
            then
            
                /*******************************************/
                /* More than 1 value so loop through these */
                /*******************************************/
                for i in vals_lv.first..vals_lv.last 
                loop
                    err_pnt_lv  := 750;
                    /**********************************************************/
                    /* Data for Piped results.                                */
                    /* This is what gets sent back to the user                */
                    /**********************************************************/
                    --DBMS_OUTPUT.PUT_LINE('ATTIBUTE_NAME: ' || attrib_nm_lv || ' = ' || SUBSTR(vals_lv(i),1,200));

                    pipe row
                    (
                        ad_user_t
                        (attribute_name => attrib_nm_lv,
                            attribute_value => substr(vals_lv(i),1,200)
                        )
                    );
                end loop; -- FOR i in vals_lv.FIRST..vals_lv.LAST
            end if; -- if vals_lv.COUNT > 0 
            /***************************************/
            /* Get the next Attribute for the loop */
            /***************************************/
            err_pnt_lv  := 760;

            attrib_nm_lv := dbms_ldap.next_attribute
                                (
                                    session_id_lv,
                                    entry_lv,
                                    ber_element_lv
                                );
                                
            attrib_idx_lv := attrib_idx_lv+1;
            
        end loop; -- while attrib_nm_lv IS NOT NULL 
                
        /*********************************/
        /* Pipe the data out to the type */
        /*********************************/
        /*****************/
        /* Get the entry */
        /*****************/
        err_pnt_lv      := 770;
        entry_lv        := dbms_ldap.next_entry(session_id_lv, entry_lv);
        entry_idx_lv    := entry_idx_lv+1;

    end loop; -- while entry_lv IS NOT NULL 
    /********************/    
    /* End LDAP Session */
    /********************/
    err_pnt_lv  := 780;
    end_lv      := dbms_ldap.unbind_s (session_id_lv);
    
    if (debug_ip = 'Y')
    then
        utl_file.put_line(file_lv, 'Completed: ' || proc_nm_lv);            
        utl_file.fflush(file_lv); -- Flush the contents
    end if;    
    
    return;
exception
    when no_data_needed     
    then
        dbms_output.put_line ( '***>>> CLEAN UP' );
        return;

    when ldap_failed
    then
    
    
        err_msg_lv  := 'DB-FUNCTION ERROR. AEDBA.CVTY'
                    || ' Unhandled AD Error.';

        err_num_lv := -20099;
    
        if (debug_ip = 'Y')
        then
            utl_file.put_line(file_lv, err_pnt_lv || ' ' || err_msg_lv);        
            utl_file.fflush(file_lv); -- Flush the contents
        end if;
    
        raise_application_error (err_num_lv, err_pnt_lv || ' ' || err_msg_lv);
        
    when dbms_ldap.general_error 
    then
        err_msg_lv  := 'DB-FUNCTION ERROR. AEDBA.CVTY'
                    || ' DBMS_LDAP.GENERAL_ERROR.'
                    || sqlerrm;

        err_num_lv := -20099;
        
        if (debug_ip = 'Y')
        then
            utl_file.put_line(file_lv, err_pnt_lv || ' ' || err_msg_lv);        
            utl_file.fflush(file_lv); -- Flush the contents
        end if;

       raise_application_error (err_num_lv, err_pnt_lv || ' ' || err_msg_lv); 
 
    when others then
        err_msg_lv  := 'DB-FUNCTION ERROR. AEDBA.CVTY'
                    || ' OTHER ERROR.'
                    || sqlerrm;

        err_num_lv := -20099;
        
        if (debug_ip = 'Y')
        then
            utl_file.put_line(file_lv, err_pnt_lv || ' ' || err_msg_lv);        
            utl_file.fflush(file_lv); -- Flush the contents
        end if;
        
        raise_application_error (err_num_lv, err_pnt_lv || ' ' || err_msg_lv);         

    
end caremarkrx;
/******************************************************************************/
/* Function ------------------------------------------------------------------*/
/******************************************************************************/
function corp 
( 
    emp_id_ip      varchar2,
    search_type_ip char, -- E = Employee ID, S = sAMAccountName
    file_ip        utl_file.file_type default null,    
    debug_ip       char default 'N'
)  
return AEDBA.ad_user_ct pipelined as
    /***************/
    /* LDAP Values */
    /***************/
    host_lv         varchar2(256);
    port_lv         varchar2(256);
    auth_acct_lv    varchar2(256);
    pw_lv           varchar2(256);
    base_dn_lv      varchar2(256);

    /**************************************/
    /* Error Handling Constants/Variables */
    /**************************************/
    proc_nm_lv          varchar2(50) := 'corp';
    err_msg_lv          varchar2(4000);
    err_num_lv          number;    
    err_pnt_lv          number;

    /***********************/
    /* DBMS_LDAP variables */
    /***********************/
    atttrib_lv      dbms_ldap.string_collection;
    ber_element_lv  dbms_ldap.ber_element;
    entry_lv        dbms_ldap.message;
    msg_lv          dbms_ldap.message; 
    session_id_lv   dbms_ldap.session;
    vals_lv         dbms_ldap.string_collection ;
    
    /*******************/
    /* Local Variables */
    /*******************/
    attrib_idx_lv       pls_integer;
    attrib_nm_lv        varchar2(256);
    dn_lv               varchar2(256);
    end_lv              pls_integer;
    entry_idx_lv        pls_integer;
    file_lv             utl_file.file_type;   
    file_is_open_lv          boolean default false;    
    ldap_mstr_id_lv     number(11) default 1; 
    node_parent_lv      clob;
    old_nc_lv           varchar2(1000);
    result_lv           pls_integer;
    retval_lv           pls_integer;
    search_str_lv       varchar2(4000);
    split_string_lv     varchar2(32767);
    xml_lv              clob;
    /********************/
    /* Output Variables */
    /********************/
    oranet_op       varchar2(32767);
    sid_op          varchar2(50);
    
    /**************/
    /* Exceptions */
    /**************/
    ldap_failed  exception;
BEGIN
    err_pnt_lv  := 790;
    retval_lv   := -1;

    if (debug_ip = 'Y')
    then
        file_is_open_lv := utl_file.is_open(file_ip);
        
        if (file_is_open_lv = false)
        then
            file_lv := utl_file.fopen('APEX_LOGS', pkg_name_gc || '_' || proc_nm_lv || '.log', 'A');
            utl_file.put_line(file_lv, rpad('-',80,'-'));
            utl_file.put_line(file_lv, 'Debug Mode ON for:' || pkg_name_gc || '_' || proc_nm_lv);
            utl_file.fflush(file_lv); -- Flush the contents
        else
            file_lv := file_ip;
            utl_file.put_line(file_lv, '....Sub Process Call: ' || pkg_name_gc || '_' || proc_nm_lv);
            utl_file.fflush(file_lv); -- Flush the contents
        end if;

        utl_file.put_line(file_lv, 'INPUT PARAMETERS............');       
        utl_file.put_line(file_lv, (rpad('emp_id_ip', 35, '.')|| '= ' || emp_id_ip));
        utl_file.put_line(file_lv, (rpad('search_type_ip',  35, '.')|| '= ' || search_type_ip));
        utl_file.fflush(file_lv); -- Flush the contents        
    end if;        

    /**************************/
    /* Get the AD Credentials */
    /**************************/
    if (debug_ip = 'Y')
    then
        utl_file.put_line(file_lv, '');        
        utl_file.put_line(file_lv, 'Fetching AD Credentials');        
        utl_file.fflush(file_lv); -- Flush the contents
    end if;
    
    err_pnt_lv  := 800;
    
    select 
        a1.config_val,
        a2.config_val,
        a3.config_val,
        a4.config_val,
        a5.config_val
    into
        host_lv,
        port_lv,
        auth_acct_lv,
        pw_lv,
        base_dn_lv
    from 
        ad_config a1,
        ad_config a2, 
        ad_config a3, 
        ad_config a4, 
        ad_config a5 
    where 
        a1.config_var = 'CVS_AD_SVR'
    and a2.config_var = 'CVS_AD_PORT'
    and a3.config_var = 'CVS_AD_AUTH'
    and a4.config_var = 'CVS_AD_PW'
    and a5.config_var = 'CVS_AD_BASE';    

    /**********************************************************/
    /* Choosing exceptions to be raised by DBMS_LDAP library. */
    /**********************************************************/
    if (debug_ip = 'Y')
    then
        utl_file.put_line(file_lv, 'Setting exception options');        
        utl_file.fflush(file_lv); -- Flush the contents
    end if;
    
    err_pnt_lv              := 810;
    dbms_ldap.use_exception := true;

    /************************/
    /* Get a session Handle */
    /************************/
    if (debug_ip = 'Y')
    then
        utl_file.put_line(file_lv, 'Setting session handle');        
        utl_file.fflush(file_lv); -- Flush the contents
    end if;

    err_pnt_lv      := 820;    
    session_id_lv   := dbms_ldap.init(host_lv, port_lv);
    
    /***********************************************************/
    /* Establish Connection to LDAP server                     */ 
    /***********************************************************/
    if (debug_ip = 'Y')
    then
        utl_file.put_line(file_lv, 'Establishing AD connection');        
        utl_file.fflush(file_lv); -- Flush the contents
    end if;
    
    err_pnt_lv  := 830;   
    result_lv   := dbms_ldap.simple_bind_s
                ( 
                    session_id_lv, 
                    auth_acct_lv, 
                    pw_lv 
                );

    if (result_lv != 0) 
    then 
        if (debug_ip = 'Y')
        then
            utl_file.put_line(file_lv, '....Connection Failed');        
            utl_file.fflush(file_lv); -- Flush the contents
        end if;
    
        raise ldap_failed;
    end if;

    if (debug_ip = 'Y')
    then
        utl_file.put_line(file_lv, '....Connected');        
        utl_file.fflush(file_lv); -- Flush the contents
    end if;

    /**************************************************/
    /* Now do the LDAP search For All Entries         */
    /**************************************************/
    if (debug_ip = 'Y')
    then
        utl_file.put_line(file_lv, '....Starting Search');        
        utl_file.fflush(file_lv); -- Flush the contents
    end if;
    
    err_pnt_lv      := 840;   
    atttrib_lv(1)   := '*'; -- retrieve all attributes 
    
    
    if (search_type_ip = 'E')
    then
        search_str_lv := '(&(objectclass=top)(employeeid=' || emp_id_ip || '))';
    else
        --search_str_lv := '(&(objectclass=top)(sAMAccountName=' || emp_id_ip || '))';
        search_str_lv := '(&(objectclass=top)(mailnickname=' || emp_id_ip || '))';
    
        --search_str_lv := '(&(objectclass=top)(sAMAccountName=' || emp_id_ip || '))';
        --search_str_lv := '(&(objectclass=top)(mailnickname=' || emp_id_ip || '))'
    end if;
    
    retval_lv := dbms_ldap.search_s
                    (
                        session_id_lv, 
                        base_dn_lv, 
                        dbms_ldap.scope_subtree,
                        search_str_lv,
                        --'(&(objectclass=top)(employeeid=' || emp_id_ip || '))',
                        --'(&(objectclass=top)(cn=' || emp_id_ip || '))',                             
                        --'(&(objectclass=top)(sAMAccountName=' || emp_id_ip || '))',
                        atttrib_lv,
                        0,
                        msg_lv);
                        
    /****************************************/    
    /* count the number of entries returned */
    /****************************************/
    err_pnt_lv  := 850; 
    retval_lv   := dbms_ldap.count_entries(session_id_lv, msg_lv);

    if (debug_ip = 'Y')
    then
        utl_file.put_line(file_lv, '....Entries: ' || retval_lv);        
        utl_file.fflush(file_lv); -- Flush the contents
    end if;
    
    /***********************/
    /* get the first entry */
    /***********************/
    err_pnt_lv      := 860;     
    entry_lv        := dbms_ldap.first_entry(session_id_lv, msg_lv);
    entry_idx_lv    := 1;

    /***********************************************/
    /* Loop through each of the entries one by one */
    /***********************************************/
    err_pnt_lv      := 870;
    while entry_lv is not null 
    loop
        /***************************/
        /* print the current entry */
        /***************************/
        err_pnt_lv  := 880;
        dn_lv       := dbms_ldap.get_dn(session_id_lv, entry_lv);
        
        /*****************/
        /* Get Attribute */
        /*****************/
        err_pnt_lv      := 890;
        dbms_ldap.utf8_conversion := false; 
        
        attrib_nm_lv    := dbms_ldap.first_attribute
                            (
                                session_id_lv,
                                entry_lv, 
                                ber_element_lv
                            );
        attrib_idx_lv := 1;
        
        /*************************************************/
        /* Loop through the attribute and get the values */
        /*************************************************/
        err_pnt_lv      := 900;
        while attrib_nm_lv is not null 
        loop
            err_pnt_lv  := 910;
            vals_lv     := dbms_ldap.get_values 
                            (
                                session_id_lv, 
                                entry_lv,
                                attrib_nm_lv
                            );
                            
            if vals_lv.count > 0 
            then
                /*******************************************/
                /* More than 1 value so loop through these */
                /*******************************************/
                for i in vals_lv.first..vals_lv.last 
                loop
                    err_pnt_lv  := 920;
                    /**********************************************************/
                    /* data for piped results.                                */
                    /* this is what gets sent back to the user                */
                    /**********************************************************/
                    /*
                    if (debug_ip = 'Y')
                    then
                        utl_file.put_line(file_lv, '......attibute_name: ' || attrib_nm_lv || ' = ' || substr(vals_lv(i),1,200));        
                        utl_file.fflush(file_lv); -- Flush the contents
                    end if;
                    */
                    
                    pipe row
                    (
                        ad_user_t
                        (attribute_name => attrib_nm_lv,
                            attribute_value => substr(vals_lv(i),1,200)
                        )
                    );
                end loop; -- FOR i in vals_lv.FIRST..vals_lv.LAST
            end if; -- if vals_lv.COUNT > 0 
            /***************************************/
            /* Get the next Attribute for the loop */
            /***************************************/
            err_pnt_lv  := 930;

            attrib_nm_lv := dbms_ldap.next_attribute
                                (
                                    session_id_lv,
                                    entry_lv,
                                    ber_element_lv
                                );
                                
            attrib_idx_lv := attrib_idx_lv+1;
            
        end loop; -- while attrib_nm_lv IS NOT NULL 
                
        /*********************************/
        /* Pipe the data out to the type */
        /*********************************/
        /*****************/
        /* Get the entry */
        /*****************/
        err_pnt_lv      := 940;
        entry_lv        := dbms_ldap.next_entry(session_id_lv, entry_lv);
        entry_idx_lv    := entry_idx_lv+1;

    end loop; -- while entry_lv IS NOT NULL 

    /* Second Search --------------*/
    retval_lv := dbms_ldap.search_s
                    (
                        session_id_lv, 
                        base_dn_lv, 
                        dbms_ldap.scope_subtree,
                        --'(&(objectclass=top)(employeeid=' || emp_id_ip || '))',
                        '(&(objectclass=top)(cn=' || emp_id_ip || '))',                        
                        atttrib_lv,
                        0,
                        msg_lv);
          
    /****************************************/    
    /* count the number of entries returned */
    /****************************************/
    err_pnt_lv  := 950; 
    retval_lv   := dbms_ldap.count_entries(session_id_lv, msg_lv);
    
    /***********************/
    /* get the first entry */
    /***********************/
    err_pnt_lv      := 960;     
    entry_lv        := dbms_ldap.first_entry(session_id_lv, msg_lv);
    entry_idx_lv    := 1;

    /***********************************************/
    /* Loop through each of the entries one by one */
    /***********************************************/
    err_pnt_lv      := 970;
    while entry_lv is not null 
    loop
        /***************************/
        /* Print the current entry */
        /***************************/
        err_pnt_lv  := 980;
        dn_lv       := dbms_ldap.get_dn(session_id_lv, entry_lv);
        
        /*****************/
        /* Get Attribute */
        /*****************/
        err_pnt_lv      := 990;
        dbms_ldap.utf8_conversion := false; 
        
        attrib_nm_lv    := dbms_ldap.first_attribute
                            (
                                session_id_lv,
                                entry_lv, 
                                ber_element_lv
                            );
        attrib_idx_lv := 1;
        
        /*************************************************/
        /* Loop through the attribute and get the values */
        /*************************************************/
        err_pnt_lv      := 1000;
        while attrib_nm_lv is not null 
        loop
            err_pnt_lv  := 1010;
            vals_lv     := dbms_ldap.get_values 
                            (
                                session_id_lv, 
                                entry_lv,
                                attrib_nm_lv
                            );
                            
            if vals_lv.count > 0 
            then
            
                /*******************************************/
                /* More than 1 value so loop through these */
                /*******************************************/
                for i in vals_lv.first..vals_lv.last 
                loop
                    err_pnt_lv  := 1020;
                    /**********************************************************/
                    /* Data for Piped results.                                */
                    /* This is what gets sent back to the user                */
                    /**********************************************************/
                    --DBMS_OUTPUT.PUT_LINE('ATTIBUTE_NAME: ' || attrib_nm_lv || ' = ' || SUBSTR(vals_lv(i),1,200));

                    pipe row
                    (
                        ad_user_t
                        (attribute_name => attrib_nm_lv,
                            attribute_value => substr(vals_lv(i),1,200)
                        )
                    );
                end loop; -- FOR i in vals_lv.FIRST..vals_lv.LAST
            end if; -- if vals_lv.COUNT > 0 
            /***************************************/
            /* Get the next Attribute for the loop */
            /***************************************/
            err_pnt_lv  := 1030;

            attrib_nm_lv := dbms_ldap.next_attribute
                                (
                                    session_id_lv,
                                    entry_lv,
                                    ber_element_lv
                                );
                                
            attrib_idx_lv := attrib_idx_lv+1;
            
        end loop; -- while attrib_nm_lv IS NOT NULL 
                
        /*********************************/
        /* Pipe the data out to the type */
        /*********************************/
        /*****************/
        /* Get the entry */
        /*****************/
        err_pnt_lv      := 1040;
        entry_lv        := dbms_ldap.next_entry(session_id_lv, entry_lv);
        entry_idx_lv    := entry_idx_lv+1;

    end loop; -- while entry_lv IS NOT NULL 
    /********************/    
    /* End LDAP Session */
    /********************/
    err_pnt_lv  := 1050;
    end_lv      := dbms_ldap.unbind_s (session_id_lv);
    
    if (debug_ip = 'Y')
    then
        utl_file.put_line(file_lv, 'Completed: ' || proc_nm_lv);            
        utl_file.fflush(file_lv); -- Flush the contents
    end if;    
    
    return;
exception
    when no_data_needed     
    then
        dbms_output.put_line ( '***>>> CLEAN UP' );
        return;
    
    when ldap_failed
    then
    
    
        err_msg_lv  := 'DB-FUNCTION ERROR. AEDBA.CVTY'
                    || ' Unhandled AD Error.';

        err_num_lv := -20099;
    
        if (debug_ip = 'Y')
        then
            utl_file.put_line(file_lv, err_pnt_lv || ' ' || err_msg_lv);        
            utl_file.fflush(file_lv); -- Flush the contents
        end if;
    
        raise_application_error (err_num_lv, err_pnt_lv || ' ' || err_msg_lv);
        
    when dbms_ldap.general_error 
    then
        err_msg_lv  := 'DB-FUNCTION ERROR. AEDBA.CVTY'
                    || ' DBMS_LDAP.GENERAL_ERROR.'
                    || sqlerrm;

        err_num_lv := -20099;
        
        if (debug_ip = 'Y')
        then
            utl_file.put_line(file_lv, err_pnt_lv || ' ' || err_msg_lv);        
            utl_file.fflush(file_lv); -- Flush the contents
        end if;

       raise_application_error (err_num_lv, err_pnt_lv || ' ' || err_msg_lv); 
 
    when others then
        err_msg_lv  := 'DB-FUNCTION ERROR. AEDBA.CVTY'
                    || ' OTHER ERROR.'
                    || sqlerrm;

        err_num_lv := -20099;
        
        if (debug_ip = 'Y')
        then
            utl_file.put_line(file_lv, err_pnt_lv || ' ' || err_msg_lv);        
            utl_file.fflush(file_lv); -- Flush the contents
        end if;
        
        raise_application_error (err_num_lv, err_pnt_lv || ' ' || err_msg_lv);         

    
end corp;
/******************************************************************************/
/* Function ------------------------------------------------------------------*/
/******************************************************************************/
function cvs 
( 
    emp_id_ip      varchar2,
    search_type_ip char, -- E = Employee ID, S = sAMAccountName
    file_ip        utl_file.file_type default null,    
    debug_ip       char default 'N'
)  
return AEDBA.ad_user_ct pipelined as
    /***************/
    /* LDAP Values */
    /***************/
    host_lv         varchar2(256);
    port_lv         varchar2(256);
    auth_acct_lv    varchar2(256);
    pw_lv           varchar2(256);
    base_dn_lv      varchar2(256);

    /**************************************/
    /* Error Handling Constants/Variables */
    /**************************************/
    proc_nm_lv          varchar2(50) := 'cvs';
    err_msg_lv          varchar2(4000);
    err_num_lv          number;    
    err_pnt_lv          number;

    /***********************/
    /* DBMS_LDAP variables */
    /***********************/
    atttrib_lv      dbms_ldap.string_collection;
    ber_element_lv  dbms_ldap.ber_element;
    entry_lv        dbms_ldap.message;
    msg_lv          dbms_ldap.message; 
    session_id_lv   dbms_ldap.session;
    vals_lv         dbms_ldap.string_collection ;
    
    /*******************/
    /* Local Variables */
    /*******************/
    attrib_idx_lv       pls_integer;
    attrib_nm_lv        varchar2(256);
    dn_lv               varchar2(256);
    end_lv              pls_integer;
    entry_idx_lv        pls_integer;
    file_lv             utl_file.file_type;   
    file_is_open_lv     boolean default false;    
    ldap_mstr_id_lv     number(11) default 1; 
    node_parent_lv      clob;
    old_nc_lv           varchar2(1000);
    result_lv           pls_integer;
    retval_lv           pls_integer;
    search_str_lv       varchar2(4000);
    split_string_lv     varchar2(32767);
    xml_lv              clob;
    /********************/
    /* Output Variables */
    /********************/
    oranet_op       varchar2(32767);
    sid_op          varchar2(50);
    
    /**************/
    /* Exceptions */
    /**************/
    ldap_failed  exception;
BEGIN
    err_pnt_lv  := 1060;
    retval_lv   := -1;
        
    if (debug_ip = 'Y')
    then
        file_is_open_lv := utl_file.is_open(file_ip);
        
        if (file_is_open_lv = false)
        then
            file_lv := utl_file.fopen('APEX_LOGS', pkg_name_gc || '_' || proc_nm_lv || '.log', 'A');
            utl_file.put_line(file_lv, rpad('-',80,'-'));
            utl_file.put_line(file_lv, 'Debug Mode ON for:' || pkg_name_gc || '_' || proc_nm_lv);
            utl_file.fflush(file_lv); -- Flush the contents
        else
            file_lv := file_ip;
            utl_file.put_line(file_lv, '....Sub Process Call: ' || pkg_name_gc || '_' || proc_nm_lv);
            utl_file.fflush(file_lv); -- Flush the contents
        end if;

        utl_file.put_line(file_lv, 'INPUT PARAMETERS............');       
        utl_file.put_line(file_lv, (rpad('emp_id_ip', 35, '.')|| '= ' || emp_id_ip));
        utl_file.put_line(file_lv, (rpad('search_type_ip',  35, '.')|| '= ' || search_type_ip));
        utl_file.fflush(file_lv); -- Flush the contents        
    end if;        

    /**************************/
    /* Get the AD Credentials */
    /**************************/
    if (debug_ip = 'Y')
    then
        utl_file.put_line(file_lv, '');        
        utl_file.put_line(file_lv, 'Fetching AD Credentials');        
        utl_file.fflush(file_lv); -- Flush the contents
    end if;
    
    err_pnt_lv  := 1070;
    
    select 
        a1.config_val,
        a2.config_val,
        a3.config_val,
        a4.config_val,
        a5.config_val
    into
        host_lv,
        port_lv,
        auth_acct_lv,
        pw_lv,
        base_dn_lv
    from 
        ad_config a1,
        ad_config a2, 
        ad_config a3, 
        ad_config a4, 
        ad_config a5 
    where 
        a1.config_var = 'CVS_AD_SVR'
    and a2.config_var = 'CVS_AD_PORT'
    and a3.config_var = 'CVS_AD_AUTH'
    and a4.config_var = 'CVS_AD_PW'
    and a5.config_var = 'CVS_AD_BASE';    

    /**********************************************************/
    /* Choosing exceptions to be raised by DBMS_LDAP library. */
    /**********************************************************/
    if (debug_ip = 'Y')
    then
        utl_file.put_line(file_lv, 'Setting exception options');        
        utl_file.fflush(file_lv); -- Flush the contents
    end if;
    
    err_pnt_lv              := 1080;
    dbms_ldap.use_exception := true;

    /************************/
    /* Get a session Handle */
    /************************/
    if (debug_ip = 'Y')
    then
        utl_file.put_line(file_lv, 'Setting session handle');        
        utl_file.fflush(file_lv); -- Flush the contents
    end if;

    err_pnt_lv      := 1090;    
    session_id_lv   := dbms_ldap.init(host_lv, port_lv);
    
    /***********************************************************/
    /* Establish Connection to LDAP server                     */ 
    /***********************************************************/
    if (debug_ip = 'Y')
    then
        utl_file.put_line(file_lv, 'Establishing AD connection');        
        utl_file.fflush(file_lv); -- Flush the contents
    end if;
    
    err_pnt_lv  := 1100;   
    result_lv   := dbms_ldap.simple_bind_s
                ( 
                    session_id_lv, 
                    auth_acct_lv, 
                    pw_lv 
                );

    if (result_lv != 0) 
    then 
        if (debug_ip = 'Y')
        then
            utl_file.put_line(file_lv, '....Connection Failed');        
            utl_file.fflush(file_lv); -- Flush the contents
        end if;
    
        raise ldap_failed;
    end if;

    if (debug_ip = 'Y')
    then
        utl_file.put_line(file_lv, '....Connected');        
        utl_file.fflush(file_lv); -- Flush the contents
    end if;

    /**************************************************/
    /* Now do the LDAP search For All Entries         */
    /**************************************************/
    if (debug_ip = 'Y')
    then
        utl_file.put_line(file_lv, '....Starting Search');        
        utl_file.fflush(file_lv); -- Flush the contents
    end if;
    
    err_pnt_lv      := 1110;   
    atttrib_lv(1)   := '*'; -- retrieve all attributes 
    
    
    if (search_type_ip = 'E')
    then
        search_str_lv := '(&(objectclass=top)(employeeid=' || emp_id_ip || '))';
    else
        --search_str_lv := '(&(objectclass=top)(sAMAccountName=' || emp_id_ip || '))';
        search_str_lv := '(&(objectclass=top)(mailnickname=' || emp_id_ip || '))';
        
    end if;
    
    retval_lv := dbms_ldap.search_s
                    (
                        session_id_lv, 
                        base_dn_lv, 
                        dbms_ldap.scope_subtree,
                        search_str_lv,
                        --'(&(objectclass=top)(employeeid=' || emp_id_ip || '))',
                        --'(&(objectclass=top)(cn=' || emp_id_ip || '))',                             
                        --'(&(objectclass=top)(sAMAccountName=' || emp_id_ip || '))',
                        atttrib_lv,
                        0,
                        msg_lv);
                        
    /****************************************/    
    /* count the number of entries returned */
    /****************************************/
    err_pnt_lv  := 1120; 
    retval_lv   := dbms_ldap.count_entries(session_id_lv, msg_lv);

    if (debug_ip = 'Y')
    then
        utl_file.put_line(file_lv, '....Entries: ' || retval_lv);        
        utl_file.fflush(file_lv); -- Flush the contents
    end if;
    
    /***********************/
    /* get the first entry */
    /***********************/
    err_pnt_lv      := 1130;     
    entry_lv        := dbms_ldap.first_entry(session_id_lv, msg_lv);
    entry_idx_lv    := 1;

    /***********************************************/
    /* Loop through each of the entries one by one */
    /***********************************************/
    err_pnt_lv      := 1140;
    while entry_lv is not null 
    loop
        /***************************/
        /* print the current entry */
        /***************************/
        err_pnt_lv  := 1150;
        dn_lv       := dbms_ldap.get_dn(session_id_lv, entry_lv);
        
        /*****************/
        /* Get Attribute */
        /*****************/
        err_pnt_lv      := 1160;
        dbms_ldap.utf8_conversion := false; 
        
        attrib_nm_lv    := dbms_ldap.first_attribute
                            (
                                session_id_lv,
                                entry_lv, 
                                ber_element_lv
                            );
        attrib_idx_lv := 1;
        
        /*************************************************/
        /* Loop through the attribute and get the values */
        /*************************************************/
        err_pnt_lv      := 1170;
        while attrib_nm_lv is not null 
        loop
            err_pnt_lv  := 1180;
            vals_lv     := dbms_ldap.get_values 
                            (
                                session_id_lv, 
                                entry_lv,
                                attrib_nm_lv
                            );
                            
            if vals_lv.count > 0 
            then
                /*******************************************/
                /* More than 1 value so loop through these */
                /*******************************************/
                for i in vals_lv.first..vals_lv.last 
                loop
                    err_pnt_lv  := 1190;
                    /**********************************************************/
                    /* data for piped results.                                */
                    /* this is what gets sent back to the user                */
                    /**********************************************************/
                    /*
                    if (debug_ip = 'Y')
                    then
                        utl_file.put_line(file_lv, '......attibute_name: ' || attrib_nm_lv || ' = ' || substr(vals_lv(i),1,200));        
                        utl_file.fflush(file_lv); -- Flush the contents
                    end if;
                    */
                    
                    pipe row
                    (
                        ad_user_t
                        (attribute_name => attrib_nm_lv,
                            attribute_value => substr(vals_lv(i),1,200)
                        )
                    );
                end loop; -- FOR i in vals_lv.FIRST..vals_lv.LAST
            end if; -- if vals_lv.COUNT > 0 
            /***************************************/
            /* Get the next Attribute for the loop */
            /***************************************/
            err_pnt_lv  := 2000;

            attrib_nm_lv := dbms_ldap.next_attribute
                                (
                                    session_id_lv,
                                    entry_lv,
                                    ber_element_lv
                                );
                                
            attrib_idx_lv := attrib_idx_lv+1;
            
        end loop; -- while attrib_nm_lv IS NOT NULL 
                
        /*********************************/
        /* Pipe the data out to the type */
        /*********************************/
        /*****************/
        /* Get the entry */
        /*****************/
        err_pnt_lv      := 2010;
        entry_lv        := dbms_ldap.next_entry(session_id_lv, entry_lv);
        entry_idx_lv    := entry_idx_lv+1;

    end loop; -- while entry_lv IS NOT NULL 

    /* Second Search --------------*/
    retval_lv := dbms_ldap.search_s
                    (
                        session_id_lv, 
                        base_dn_lv, 
                        dbms_ldap.scope_subtree,
                        --'(&(objectclass=top)(employeeid=' || emp_id_ip || '))',
                        '(&(objectclass=top)(cn=' || emp_id_ip || '))',                        
                        atttrib_lv,
                        0,
                        msg_lv);
                        
    /****************************************/    
    /* count the number of entries returned */
    /****************************************/
    err_pnt_lv  := 2020; 
    retval_lv   := dbms_ldap.count_entries(session_id_lv, msg_lv);
    
    /***********************/
    /* get the first entry */
    /***********************/
    err_pnt_lv      := 2030;     
    entry_lv        := dbms_ldap.first_entry(session_id_lv, msg_lv);
    entry_idx_lv    := 1;

    /***********************************************/
    /* Loop through each of the entries one by one */
    /***********************************************/
    err_pnt_lv      := 2040;
    while entry_lv is not null 
    loop
        /***************************/
        /* Print the current entry */
        /***************************/
        err_pnt_lv  := 2050;
        dn_lv       := dbms_ldap.get_dn(session_id_lv, entry_lv);
        
        /*****************/
        /* Get Attribute */
        /*****************/
        err_pnt_lv      := 2060;
        dbms_ldap.utf8_conversion := false; 
        
        attrib_nm_lv    := dbms_ldap.first_attribute
                            (
                                session_id_lv,
                                entry_lv, 
                                ber_element_lv
                            );
        attrib_idx_lv := 1;
        
        /*************************************************/
        /* Loop through the attribute and get the values */
        /*************************************************/
        err_pnt_lv      := 2070;
        while attrib_nm_lv is not null 
        loop
            err_pnt_lv  := 2080;
            vals_lv     := dbms_ldap.get_values 
                            (
                                session_id_lv, 
                                entry_lv,
                                attrib_nm_lv
                            );
                            
            if vals_lv.count > 0 
            then
            
                /*******************************************/
                /* More than 1 value so loop through these */
                /*******************************************/
                for i in vals_lv.first..vals_lv.last 
                loop
                    err_pnt_lv  := 2090;
                    /**********************************************************/
                    /* Data for Piped results.                                */
                    /* This is what gets sent back to the user                */
                    /**********************************************************/
                    --DBMS_OUTPUT.PUT_LINE('ATTIBUTE_NAME: ' || attrib_nm_lv || ' = ' || SUBSTR(vals_lv(i),1,200));

                    pipe row
                    (
                        ad_user_t
                        (attribute_name => attrib_nm_lv,
                            attribute_value => substr(vals_lv(i),1,200)
                        )
                    );
                end loop; -- FOR i in vals_lv.FIRST..vals_lv.LAST
            end if; -- if vals_lv.COUNT > 0 
            /***************************************/
            /* Get the next Attribute for the loop */
            /***************************************/
            err_pnt_lv  := 2100;

            attrib_nm_lv := dbms_ldap.next_attribute
                                (
                                    session_id_lv,
                                    entry_lv,
                                    ber_element_lv
                                );
                                
            attrib_idx_lv := attrib_idx_lv+1;
            
        end loop; -- while attrib_nm_lv IS NOT NULL 
                
        /*********************************/
        /* Pipe the data out to the type */
        /*********************************/
        /*****************/
        /* Get the entry */
        /*****************/
        err_pnt_lv      := 2110;
        entry_lv        := dbms_ldap.next_entry(session_id_lv, entry_lv);
        entry_idx_lv    := entry_idx_lv+1;

    end loop; -- while entry_lv IS NOT NULL 
    /********************/    
    /* End LDAP Session */
    /********************/
    err_pnt_lv  := 2120;
    end_lv      := dbms_ldap.unbind_s (session_id_lv);
    
    if (debug_ip = 'Y')
    then
        utl_file.put_line(file_lv, 'Completed: ' || proc_nm_lv);            
        utl_file.fflush(file_lv); -- Flush the contents
    end if;    
    
    return;
exception
    when no_data_needed     
    then
        dbms_output.put_line ( '***>>> CLEAN UP' );
        return;
    when ldap_failed
    then
    
    
        err_msg_lv  := 'DB-FUNCTION ERROR. AEDBA.CVTY'
                    || ' Unhandled AD Error.';

        err_num_lv := -20099;
    
        if (debug_ip = 'Y')
        then
            utl_file.put_line(file_lv, err_pnt_lv || ' ' || err_msg_lv);        
            utl_file.fflush(file_lv); -- Flush the contents
        end if;
    
        raise_application_error (err_num_lv, err_pnt_lv || ' ' || err_msg_lv);
        
    when dbms_ldap.general_error 
    then
        err_msg_lv  := 'DB-FUNCTION ERROR. AEDBA.CVTY'
                    || ' DBMS_LDAP.GENERAL_ERROR.'
                    || sqlerrm;

        err_num_lv := -20099;
        
        if (debug_ip = 'Y')
        then
            utl_file.put_line(file_lv, err_pnt_lv || ' ' || err_msg_lv);        
            utl_file.fflush(file_lv); -- Flush the contents
        end if;

       raise_application_error (err_num_lv, err_pnt_lv || ' ' || err_msg_lv); 
 
    when others then
        err_msg_lv  := 'DB-FUNCTION ERROR. AEDBA.CVTY'
                    || ' OTHER ERROR.'
                    || sqlerrm;

        err_num_lv := -20099;
        
        if (debug_ip = 'Y')
        then
            utl_file.put_line(file_lv, err_pnt_lv || ' ' || err_msg_lv);        
            utl_file.fflush(file_lv); -- Flush the contents
        end if;
        
        raise_application_error (err_num_lv, err_pnt_lv || ' ' || err_msg_lv);         

    
end cvs;
END AD_PKG;
/
GRANT EXECUTE ON AEDBA.AD_PKG TO A229515
/
GRANT EXECUTE ON AEDBA.AD_PKG TO A236120
/
GRANT EXECUTE ON AEDBA.AD_PKG TO A738300
/
GRANT EXECUTE ON AEDBA.AD_PKG TO A607483
/
GRANT EXECUTE ON AEDBA.AD_PKG TO A603481
/
GRANT EXECUTE ON AEDBA.AD_PKG TO A229515
/
GRANT EXECUTE ON AEDBA.AD_PKG TO A236120
/
GRANT EXECUTE ON AEDBA.AD_PKG TO A738300
/
GRANT EXECUTE ON AEDBA.AD_PKG TO A607483
/
GRANT EXECUTE ON AEDBA.AD_PKG TO A603481
/
