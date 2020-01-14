--------------------------------------------------------
-- Archivo creado  - jueves-diciembre-26-2013   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Package Body SGPG_CONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "SGCLATINOPER"."SGPG_CONS" AS

  /***********************************************************************************************
    NOMBRE:      SGPR_ALMA_HIST
    PROPOSITO:   PROCEDIMIENTO QUE ALMACENA LOS CONSUMOS CON MAS DE TRES MESES DE ACTIGUEDAD EN 
                 EL HISTORIAL
  /***********************************************************************************************/
  PROCEDURE SGPR_ALMA_HIST
  Is
    kn_cant_mese number := 3;
    ln_fech_limi date;  
    ln_cant_cons number;     
  Begin
    dbms_output.put_line('Almacenando consumos en el historial...');
    
    -- Obtiene la fecha limite
    select 
      ADD_MONTHS(trunc(sysdate,'MM'), - kn_cant_mese) 
    into 
      ln_fech_limi 
    from 
      dual;
      
    -- Calcula la cantidad de registros a copiar
    select 
      count(1) 
    into 
      ln_cant_cons 
    from 
      tmp_ginlogconsumos 
    where 
      trunc(GINLOGC_FECHACONSUMO, 'MM') <= ln_fech_limi;
    
    dbms_output.put_line('Cantidad de consumos a almacenar: ' || ln_cant_cons );
    if ln_cant_cons > 0 then
      -- Copia los registros que exceden la fecha limite al historial
      insert into
        tmp_ginlogconsumos_hist 
      select 
        * 
      from 
        tmp_ginlogconsumos 
      where 
        trunc(GINLOGC_FECHACONSUMO, 'MM') <= ln_fech_limi;
      
      -- Eliminar los registros copiados
      delete from 
        tmp_ginlogconsumos 
      where 
        trunc(GINLOGC_FECHACONSUMO, 'MM') <= ln_fech_limi;
      
      commit;
      dbms_output.put_line('Consumos almacenados en el historias: ' || ln_cant_cons);
    end if;
     
  Exception
    When Others Then
    dbms_output.put_line('Enviando correo de alerta: ' || SQLCODE || ' : ' || SQLERRM );
    -- Enviar correo de alerta
  End;
  
  PROCEDURE SGPR_ALMA_HIST_2
  Is
    kn_cant_mese number := 3;
    kn_cant_regi number := 100000;

    ln_time_0 number;
    ln_time_1 number;
    ln_time_2 number;
  
    Cursor lc_regi_cons 
    Is
      Select *
      from tmp_ginlogconsumos
      where trunc(GINLOGC_FECHACONSUMO, 'MM') <= ( 
        Select 
          ADD_MONTHS(trunc(sysdate,'MM'), - kn_cant_mese) 
        from 
          dual);
    
    Type lt_cons_hist 
    Is 
      Table Of lc_regi_cons%rowtype;
  
    l_cons_hist lt_cons_hist;
  Begin
    dbms_output.put_line('Iniciando el almacenamiento de consumos... ');
    Open lc_regi_cons;
    Loop
      ln_time_0 := DBMS_UTILITY.get_time;
      Fetch lc_regi_cons
        Bulk Collect into l_cons_hist
        limit kn_cant_regi;
      Exit when l_cons_hist.count = 0;
      
      ln_time_1 := DBMS_UTILITY.get_time;
      Forall i in l_cons_hist.FIRST..l_cons_hist.LAST
        Insert into 
          tmp_ginlogconsumos_hist
        values
          l_cons_hist(i);
          
      ln_time_2 := DBMS_UTILITY.get_time;
      dbms_output.put_line('Tiempo de insercion: ' || to_char((ln_time_2 - ln_time_1)/100));
      
      ln_time_1 := DBMS_UTILITY.get_time;  
      Forall i in l_cons_hist.First..l_cons_hist.count
        Delete from 
          tmp_ginlogconsumos
        where 
          GINLOGC_IDCONSUMO = l_cons_hist(i).GINLOGC_IDCONSUMO;
      /*Insert into 
          tmp_ginlogconsumos_2
          (GINLOGC_IDCONSUMO)
        values
          (l_cons_hist(i).GINLOGC_IDCONSUMO);*/
      
      ln_time_2 := DBMS_UTILITY.get_time;
      dbms_output.put_line('Tiempo de eliminacion: ' || to_char((ln_time_2 - ln_time_1)/100));
      
      Commit write nowait;
      ln_time_2 := DBMS_UTILITY.get_time;
      dbms_output.put_line('Duracion total: ' || to_char((ln_time_2 - ln_time_0)/100));
    END LOOP;
    Close lc_regi_cons;
    dbms_output.put_line('Almacenamiento de consumos terminado ');
  End;

END SGPG_CONS;

/
