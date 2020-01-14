#!/bin/sh
. /home/colebatch/sgc/resources/variables.conf

# Cargar configuraciones
sql_input=`cat ${SGC_CONF} | grep SGC_SQL_SCRIPT | awk -F"=" '{print $2}'`
sql_output=`cat ${SGC_CONF} | grep SGC_SQL_OUTPUT | awk -F"=" '{print $2}'`
sgc_user=`cat ${SGC_AUTH} | grep SGC_PROCESS_USER | awk -F"=" '{print $2}'`
sgc_pass=`cat ${SGC_AUTH} | grep SGC_PROCESS_PASS | awk -F"=" '{print $2}'`
sgc_service=`cat ${SGC_AUTH} | grep SGC_PROCESS_SERV | awk -F"=" '{print $2}'`
support_mails=`cat ${SGC_CONF} | grep SGC_SUPPORT_EMAILS | awk -F"=" '{print $2}'`
dbconnect=`cat ${SGC_CONF} | grep DBCONNECT_BIN | awk -F"=" '{print $2}'`

# Ejecutar dbconnect.sh
${dbconnect} ${sql_input} ${sql_output} ${sgc_user} ${sgc_pass} ${sgc_service}

mail_content="Almacenamiento de consumos ejecutado."
# Procesar output
output_errors=`cat ${sql_output} | grep ERROR-`
if [ ! -z "${output_errors}" ]; then
	mail_content="${mail_content}\n\nSe produjeron los siguientes errores:\n${output_errors}"
fi

#Envio de correo:
echo -e "$mail_content" | mailx -s "Alamacenamiento de Consumos" -a ${sql_output} ${support_mails}

