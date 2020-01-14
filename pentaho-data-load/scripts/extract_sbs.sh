#!/bin/sh

export PENTAHO_BASE_DIR=/opt/pentaho/pdi-ce-5.2.0.0-209
export KETTLE_JNDI_ROOT=$PENTAHO_BASE_DIR/simple-jndi

KITCHEN_FILE=${PENTAHO_BASE_DIR}/kitchen.sh

SYNC_HOME=/opt/tools/Pentaho52/INFORMA

LOG_DATE=$(date +%Y/%m/%d-%H:%M:%S)
FECHA=$(date +"%Y-%m-%d")

## variable de lenguaje
NLS_LANG=AMERICAN_AMERICA.WE8ISO8859P1
export NLS_LANG

echo  "${LOG_DATE}" "Inicio proceso batch SBS... "
echo  "${LOG_DATE}" "Cargando archivo Job..."


${KITCHEN_FILE} -file=${SYNC_HOME}/pentaho/extract_sbs_job.kjb -param:origen="$1" -level=Basic >> ${SYNC_HOME}/logs/extract_sbs_job_$FECHA.log
echo  "`date +%Y/%m/%d-%H:%M:%S` Termino proceso batch SBS."


