#!/bin/sh
. /home/carga-avales/conf/variables.conf

# TODO LIST
#	Control de ejecucion por medio del PID
#	Envio de correos con sendmail (si es posible la utilizacion de templates)
#	Definir si el log del proceso se debe mostrar al final

# Cargar configuraciones
ava_service=`cat ${AVA_AUTH} | grep AVA_PROCESS_SERV | awk -F"=" '{print $2}'`
ava_user=`cat ${AVA_AUTH} | grep AVA_PROCESS_USER | awk -F"=" '{print $2}'`
ava_pass=`cat ${AVA_AUTH} | grep AVA_PROCESS_PASS | awk -F"=" '{print $2}'`

ava_support=`cat ${AVA_CONF} | grep AVA_SUPPORT_EMAILS | awk -F"=" '{print $2}'`
dbconnect=`cat ${AVA_CONF} | grep DBCONNECT_BIN | awk -F"=" '{print $2}'`

sql_search_periodo=SP_ELPR_BUSC_PRDO.sql
sql_delete_periodo=SP_ELPR_ELIM_PRDO.sql
sql_insert_avalistas=SP_ELPR_CARG_AVAL.sql
sql_insert_avalados=SP_ELPR_CARG_SLDO.sql
sql_update_avalistas=SP_ELPR_ACTU_AVAL.sql
sql_rejected_avalistas=SP_ELPR_GENE_FILE_RCHZ_AVAL.sql
sql_rejected_avalados=SP_ELPR_GENE_FILE_RCHZ_SLDO.sql

sql_output=sql_output.log

### Funciones
executeDBConnect() {
	${dbconnect} ${1} ${2} ${ava_user} ${ava_pass} ${ava_service}
	local result=$(sed -n '/SQL>/,/SQL>/ p' ${2} | sed '1d; $d')
	$(cat ${2} >> "${AVA_LOG}/${sql_output}")
	echo "${result}"
}

executeSQL() {
	local sql=${AVA_SQL}/${1}
	local sql_tmp=${3}/${1}
	local sql_out="${sql_tmp}.out"
	$(cat ${sql} | sed "s|&{FEC_PRDO}|'${2}'|g" > ${sql_tmp})
	echo "$(executeDBConnect ${sql_tmp} ${sql_out} | grep RESULT | awk -F":" '{print $2}')"
}

searchPeriod() {
	local sql=${AVA_SQL}/${sql_search_periodo}
	local sql_tmp=${2}/${sql_search_periodo}
	local sql_out="${sql_tmp}.out"
	$(cat ${sql} | sed "s|&{FEC_PRDO}|'${1}'|g" > ${sql_tmp})
	echo "$(executeDBConnect ${sql_tmp} ${sql_out} | tr -d ' ')"
}

validatePeriod() {
	if [ -z "${1}" ]; then
		read -p "Ingrese la fecha para la carga del periodo (yyyymm):" period
		validatePeriod ${period}
	else
		is_valid=$(validateDate ${1})
        if [ ${is_valid} = "false" ]; then
			echo "Fecha[${period}] invalida, el formato de la fecha debe ser yyyymm"
			read -p "Ingrese la fecha para la carga del periodo (yyyymm):" period
			validatePeriod ${period}
		fi
	fi
}

validateDate() {
	local regex="^[0-9]{6}"
	if [[ "${1}" =~ ${regex} ]]; then
		if [ ${1:0:4} -ge 1900  ] && [ ${1:4} -le 12 ]; then
			echo "true"
		else 
			echo "false"
		fi
	else 
		echo "false"
	fi
}

formatPeriod() {
	local res=$(expr $(date +%Y) - ${1:0:4})
	local date=$(date -d "${1:4}/1 + 1 month - 1 day ${res} year" +%d/%m/%Y)
	echo "${date}"
}

createTempDirectory() {
	local dir_name="P${1}"
	local exist=$(find ${AVA_TMP} -maxdepth 1 -type d -name ${dir_name} | wc -l)
	local dir_path="${AVA_TMP}/${dir_name}"

	if [ ${exist} == 0 ]; then
		$(mkdir ${dir_path})
		echo "${dir_path}"
	else
		if [ ${2} = "true" ]; then
			$(rm -r ${dir_path})
			$(mkdir ${dir_path})
			echo "${dir_path}"
		fi
	fi
}

removeTempDirectory() {
	$(rm -r ${1})
}

initLog() {
	local amount=$(find ${AVA_LOG} -maxdepth 1 -type f -name ${sql_output} | wc -l)
	local today=$(date +"%d/%m/%Y-%H:%M:%S")
	if [ ${amount} -eq 0 ]; then
		echo "-----------------------------------------------" > "${AVA_LOG}/${sql_output}"
		echo "${today} - ${USER}" >> "${AVA_LOG}/${sql_output}"
		echo "-----------------------------------------------" >> "${AVA_LOG}/${sql_output}"
	else
		echo "-----------------------------------------------" >> "${AVA_LOG}/${sql_output}"
		echo "${today} - ${USER}" >> "${AVA_LOG}/${sql_output}"
		echo "-----------------------------------------------" >> "${AVA_LOG}/${sql_output}"
	fi	
}

sendAlert() {
	echo -e "Enviar Alerta"
}

### Procesar Carga
echo "*************************************************************************
*		 Proceso de carga de Avalaes EFX Lite  			*
*************************************************************************"

period=""
force=false

while getopts "p:f" opt; do
	case "${opt}" in
	p )
		period=${OPTARG}
		;;
	f )	
		force=true;
		;;
	\?)
		echo -e "Opcion invalida: -${OPTARG}"
		;;
	esac
done

# Inicia el log
initLog

# Validando fecha del periodo
validatePeriod ${period}

# Verifica si el directorio existe, si existe termina el programa sino crea el directorio y continua.
tmp_dir=$(createTempDirectory ${period} ${force})
if [ -z "${tmp_dir}" ]; then
	if [ ${force} = "true" ]; then
		echo "El proceso de carga no pudo ser iniciado."
                exit 1
	else
		echo "El periodo ${period} esta siendo procesado actualmente. Si esta seguro"
		echo "que el periodo no esta siendo procesado actualmente ejecute la carga "
		echo "usando la opcion -f"
		exit 1
	fi
fi

# Da formato a la fecha del periodo
period=$(formatPeriod ${period})

# Busca si el periodo fue cargado previamente
echo -ne "Verificando si el periodo ${period} fue cargado previamente...\r"
result_set=$(searchPeriod ${period} ${tmp_dir})
result=$(echo ${result_set} | grep Total | awk -F":" '{print $7}')
result=${result:4}
echo -ne "Verificando si el periodo ${period} fue cargado previamente...[done]\r"
echo -ne "\n"

# Verifica el resultado de la busqueda
regex="^[0-9]+"
if [ ! -z "${result}" ] && [[ "${result}" =~ ${regex} ]]; then

	# Si el periodo ya fue cargado, espera confirmacion del operador para continuar
	if [ "${result}" -ne 0 ]; then
		echo -e " ${result_set}"

		invalid_answer=true
		while [ ${invalid_answer} = "true" ]; do
			read -p "Periodo ${period} existente, Desea proceder con la carga? [s/n]: " continue

			case "${continue}" in
			s|S )
				# Elimina la data existente del periodo
				echo -ne "Eliminando informacion de avalados y avalistas.................\r"
				rsl_del=$(executeSQL ${sql_delete_periodo} ${period} ${tmp_dir})
				echo -ne "Eliminando informacion de avalados y avalistas.................[${rsl_del}]\r"
				echo -ne "\n"
				if [ "${rsl_del}" = "done" ]; then
					echo -ne "Cargando informacion de avalistas..............................\r"
					rsl_aval=$(executeSQL ${sql_insert_avalistas} ${period} ${tmp_dir})
					echo -ne "Cargando informacion de avalistas..............................[${rsl_aval}]\r"
					echo -ne "\n"
					
					echo -ne "Cargando informacion de avalados...............................\r"
					rsl_sldo=$(executeSQL ${sql_insert_avalados} ${period} ${tmp_dir})
					echo -ne "Cargando informacion de avalados...............................[${rsl_sldo}]\r"
					echo -ne "\n"
					
					echo -ne "Actualizando informacion de avalistas..........................\r"
					rsl_upd=$(executeSQL ${sql_update_avalistas} ${period} ${tmp_dir})
					echo -ne "Actualizando informacion de avalistas..........................[${rsl_upd}]\r"
					echo -ne "\n"
					
					echo -ne "Generando lista de avalistas rechazados........................\r"
					rsl_gen1=$(executeSQL ${sql_rejected_avalistas} ${period} ${tmp_dir})
					if [ ! -z "${rsl_gen1}" ]; then
						echo -ne "Generando lista de avalistas rechazados........................[done]\r"
						echo -ne "\n"
						echo -e "Archivo:${rsl_gen1}"
					else 
						echo -ne "Generando lista de avalistas rechazados........................[fail]\r"
						echo -ne "\n"
					fi
					
					echo -ne "Generando lista de avalados rechazados.........................\r"
					rsl_gen2=$(executeSQL ${sql_rejected_avalados} ${period} ${tmp_dir})
					if [ ! -z "${rsl_gen2}" ]; then
						echo -ne "Generando lista de avalados rechazados.........................[done]\r"
						echo -ne "\n"
						echo -e "Archivo:${rsl_gen2}"
					else 
						echo -ne "Generando lista de avalados rechazados.........................[fail]\r"
						echo -ne "\n"
					fi
					
					echo -e "Proceso de Carga Terminado"
				else
					removeTempDirectory ${tmp_dir}
					echo -e "No se pudo eliminar los registros del periodo[${period}].";
					exit 1
				fi
				invalid_answer=false
			;;
			n|N|"" )
				echo -e "Proceso de Carga Cancelado"
				sendAlert
				invalid_answer=false
			;;
			* )
				echo -e "opcion invalida: ${continue}"
			;;
			esac
		done
	else
	# Carga la nueva data del periodo
		echo -ne "Cargando informacion de avalistas..............................\r"
		rsl_aval=$(executeSQL ${sql_insert_avalistas} ${period} ${tmp_dir})
		echo -ne "Cargando informacion de avalistas..............................[${rsl_aval}]\r"
		echo -ne "\n"
		
		echo -ne "Cargando informacion de avalados...............................\r"
		rsl_sldo=$(executeSQL ${sql_insert_avalados} ${period} ${tmp_dir})
		echo -ne "Cargando informacion de avalados...............................[${rsl_sldo}]\r"
		echo -ne "\n"
		
		echo -ne "Actualizando informacion de avalistas..........................\r"
		rsl_upd=$(executeSQL ${sql_update_avalistas} ${period} ${tmp_dir})
		echo -ne "Actualizando informacion de avalistas..........................[${rsl_upd}]\r"
		echo -ne "\n"
		
		echo -ne "Generando lista de avalistas rechazados........................\r"
		rsl_gen1=$(executeSQL ${sql_rejected_avalistas} ${period} ${tmp_dir})
		if [ ! -z "${rsl_gen1}" ]; then
			echo -ne "Generando lista de avalistas rechazados........................[done]\r"
			echo -ne "\n"
			echo -e "Archivo:${rsl_gen1}"
		else 
			echo -ne "Generando lista de avalistas rechazados........................[fail]\r"
			echo -ne "\n"
		fi
		
		echo -ne "Generando lista de avalados rechazados.........................\r"
		rsl_gen2=$(executeSQL ${sql_rejected_avalados} ${period} ${tmp_dir})
		if [ ! -z "${rsl_gen2}" ]; then
			echo -ne "Generando lista de avalados rechazados.........................[done]\r"
			echo -ne "\n"
			echo -e "Archivo:${rsl_gen2}"
		else 
			echo -ne "Generando lista de avalados rechazados.........................[fail]\r"
			echo -ne "\n"
		fi
					
		echo -e "Proceso de Carga Terminado"
		
	fi
else
	removeTempDirectory ${tmp_dir}
	echo -e "No se pudo verificar si el periodo[${period}] ya ha sido cargado."
	exit 1
fi

# Elimina el directorio temporal
removeTempDirectory ${tmp_dir}

#echo "Log Result ..."
#cat ${sql_output}
