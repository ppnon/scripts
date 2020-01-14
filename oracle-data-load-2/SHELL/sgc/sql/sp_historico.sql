set head off
set trimspool off
set linesize 3000
set pagesize 2000
set feedback off
set colsep '|'
set serveroutput on
exec dbms_output.enable(20000000);

--select sysdate from dual;
--select 'ERROR-Prueba de error' as error from dual;
--select GINLOGC_IDCONSUMO, GINLOGC_IDUSUARIO, GINLOGC_FECHACONSUMO from ginlogconsumos where rownum <= 10;
select count(1) from ginlogconsumos where rownum = 0;

