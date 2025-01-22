create diskgroup DATA_01
external redundancy
disk '/dev/oracleasm/disks/VOLDAT*'
attribute 
 'sector_size'='512',
 'au_size'='4m',
 'compatible.asm' = '19.3',
 'compatible.rdbms' = '12.1';

create diskgroup FLASH_01
external redundancy
disk '/dev/oracleasm/disks/VOLFLSH*'
attribute 
 'sector_size'='512',
 'au_size'='4m',
 'compatible.asm' = '19.3',
 'compatible.rdbms' = '12.1';

create diskgroup REDOA_01
external redundancy
disk '/dev/oracleasm/disks/VOLREDO1', '/dev/oracleasm/disks/VOLREDO2'
attribute 
 'sector_size'='512',
 'au_size'='1m',
 'compatible.asm' = '19.3',
 'compatible.rdbms' = '12.1';

create diskgroup REDOB_01
external redundancy
disk '/dev/oracleasm/disks/VOLREDO3', '/dev/oracleasm/disks/VOLREDO4'
attribute 
 'sector_size'='512',
 'au_size'='1m',
 'compatible.asm' = '19.3',
 'compatible.rdbms' = '12.1';

