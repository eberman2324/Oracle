SELECT
        dg.name AS diskgroup,
        SUBSTR(a.name,1,24) AS name,
        SUBSTR(a.value,1,24) AS value
FROM
        V$ASM_DISKGROUP dg,
        V$ASM_ATTRIBUTE a
WHERE
--        dg.name like '%AOA%' and
        dg.group_number = a.group_number;

SELECT
        dg.name AS diskgroup,
        SUBSTR(d.name,1,16) AS asmdisk,
        SUBSTR(dg.compatibility,1,12) AS asm_compat,
        SUBSTR(dg.database_compatibility,1,12) AS db_compat
FROM
        V$ASM_DISKGROUP dg,
        V$ASM_DISK d
WHERE
--      dg.name LIKE 'DGROUP%' AND
        dg.group_number = d.group_number;


SELECT
        dg.name AS diskgroup,
        SUBSTR(c.instance_name,1,12) AS instance,
        SUBSTR(c.db_name,1,12) AS dbname, SUBSTR(c.SOFTWARE_VERSION,1,12) AS software,
        SUBSTR(c.COMPATIBLE_VERSION,1,12) AS compatible
FROM
        V$ASM_DISKGROUP dg,
        V$ASM_CLIENT c
WHERE
        dg.group_number = c.group_number;

