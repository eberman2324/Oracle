set linesize 360
select  OPERATION, pass, STATE, POWER, ACTUAL "ACTUAL POWER",SOFAR, EST_WORK, EST_RATE, EST_MINUTES from V$ASM_OPERATION;
