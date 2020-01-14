#!/bin/bash
# 1. download the agent in zip format and unzip it in /opt/go-agent/go-agent-01
# 2. download java jdk and unzip it in the directory of your preference, for example /opt/go-agent/java
# 3. configure the agent editing the file go-agent-01/wrapper-config/wrapper-properties.conf
# 	wrapper.app.parameter.101=https://127.0.0.1:8154/go
#	wrapper.app.parameter.102=sslVerificationMode
#   wrapper.app.parameter.103=NONE
#   wrapper.app.parameter.104=/opt/go-agent/java/bin/java
# 4. test the agent: sh go-agent-01/bin/go-agent console
# 5. check service running: systemctl status go-agent-01.service

REGEX_DIGIT='^[0-9]+$'
REGEX_BOOLEAN='^[s][i]|[n][o]$'

echo '------------------------------------------------------------------'
echo 'Instalar Agente GoCD'
echo '------------------------------------------------------------------'

INVALID=1
until [ $INVALID -ne 1 ]
do
  read -p "Ubicacion del agente [$PWD]: " AGENT_HOME
  if [ -z "$AGENT_HOME" ]; then
    AGENT_HOME=$PWD
    INVALID=0
  else
    if [[ -d $AGENT_HOME ]]; then
       INVALID=0
    else
      echo 'error: directorio no encontrado'
    fi
  fi
done

INVALID=1
until [ $INVALID -ne 1 ]
do
  read -p "Numero identificador del agente [1]: " AGENT_NUMBER
  if [ -z "$AGENT_NUMBER" ]; then
    AGENT_NUMBER=1
    INVALID=0
  else
    if [[ $AGENT_NUMBER =~ $REGEX_DIGIT ]]; then
       INVALID=0
    else
      echo 'error: numero invalido'
    fi
  fi
done

INVALID=1
until [ $INVALID -ne 1 ]
do
  read -p "Solo habilitado para el usario go (si/no) [si]: " GO_USER_ONLY
  if [ -z "$START_SERVICE_NOW" ]; then
    GO_USER_ONLY="si"
    INVALID=0
  else
    if [[ $GO_USER_ONLY =~ $REGEX_BOOLEAN ]] ; then
       INVALID=0
    else
      echo 'error: valor invalido, si/no'
    fi
  fi
done

INVALID=1
until [ $INVALID -ne 1 ]
do
  read -p "Iniciar el agente al terminar la instalacion (si/no) [si]: " START_SERVICE_NOW
  if [ -z "$START_SERVICE_NOW" ]; then
    START_SERVICE_NOW="si"
    INVALID=0
  else
    if [[ $START_SERVICE_NOW =~ $REGEX_BOOLEAN ]] ; then
       INVALID=0
    else
      echo 'error: valor invalido, si/no'
    fi
  fi
done

# change ownership and mode, so that the `go` user, and only that user
# can write to these directories
if [ "${GO_USER_ONLY}" == "si" ]; then
  chown -R go:go ${AGENT_HOME}
  chmod -R 0750 ${AGENT_HOME}
fi

# configure agent id and path
AGENT_ID="go-agent-${AGENT_NUMBER}"

sed -i -e "s@go-agent@${AGENT_ID}@g" ${AGENT_HOME}/bin/go-agent
sed -i -e "s@=go-agent\$@=${AGENT_ID}@g" \
       -e "s@/var/lib/go-agent@${AGENT_HOME}/lib@g" \
       -e "s@/var/log/go-agent@${AGENT_HOME}/logs@g" \
       -e "s@../wrapper-config/wrapper-properties.conf@${AGENT_HOME}/wrapper-config/wrapper-properties.conf@g" ${AGENT_HOME}/wrapper-config/wrapper.conf
sed -i -e "s@/var/lib/go-agent@${AGENT_HOME}/lib@g" ${AGENT_HOME}/wrapper-config/wrapper-properties.conf

# install the service 
if [ "${START_SERVICE_NOW}" == "si" ]; then
  ${AGENT_HOME}/bin/go-agent installstart
else
  ${AGENT_HOME}/bin/go-agent install
fi

exit 0

# to uninstall a service do this:
# systemctl stop [servicename]
# systemctl disable [servicename]
# rm /etc/systemd/system/[servicename]
# rm /etc/systemd/system/[servicename] symlinks that might be related
# systemctl daemon-reload
# systemctl reset-failed
