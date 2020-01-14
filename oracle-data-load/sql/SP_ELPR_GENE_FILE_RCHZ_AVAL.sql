set head off
set trimspool off
set linesize 3000
set pagesize 2000
set feedback off
set colsep '|'
set serveroutput on
exec dbms_output.enable(20000000);

DECLARE
  PD_FECH_PRDO VARCHAR2(200);
BEGIN
  PD_FECH_PRDO := &{FEC_PRDO};

  ELPG_CARG_AVAL.ELPR_GENE_FILE_RCHZ_AVAL(
    PD_FECH_PRDO => PD_FECH_PRDO
  );
END;
/
