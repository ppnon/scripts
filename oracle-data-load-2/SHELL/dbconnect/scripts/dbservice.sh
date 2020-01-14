#!/bin/sh
. /home/colebatch/dbconnect/resources/dbconnect.conf
sqlfile=$1
sqlresult=$2
ci_name=$3
ci_pass=$4
service_name=$5

#PASS_FILE
#Busqueda de BD y Usuario
db_name=`cat ${AUTH_DIR}/${AUTH_FILE} | grep ${ci_name} | grep ${service_name} | awk -F"|" '{ print $4 }'`
db_user=`cat ${AUTH_DIR}/${AUTH_FILE} | grep ${ci_name} | grep ${service_name} | awk -F"|" '{ print $5 }'`
ci_pass_file=`cat ${AUTH_DIR}/${AUTH_FILE} | grep ${ci_name} | grep ${service_name} | awk -F"|" '{ print $2 }'`

if [ "x"${ci_pass_file} = "x"${ci_pass} ]; then
	db_pass=`cat ${AUTH_DIR}/${PASS_FILE} | grep ${db_name} | grep ${db_user} | awk -F"|" '{ print $3 }'`
sqlplus ${db_user}/${db_pass}@${db_name} << EOF  >> ${sqlresult}
@${sqlfile}
quit;
EOF

else
	echo "BATCH_ERROR : El proecso no esta autorizado a ejecutar este servicio"
fi


