# LOGIN
#curl --request POST --data '{"password": "mypassword"}' https://vault.service.aws/v1/auth/ldap/login/jxg

## Get Token
#curl --request POST --data '{"password": "mypassword"}' https://vault.service.aws/v1/auth/ldap/login/jxg | jq .auth.client_token | sed -e 's/^"//' -e 's/"$//'

#apps/demo
#demo-policy
#demo-role

#vault read auth/approle/role/demo-role/role-id
#vault write -f auth/approle/role/demo-role/secret-id
#vault write auth/approle/login role_id=7a96911f-504f-95de-c713-0e2627f5b406 secret_id=083f86cc-0c57-af13-a3ec-bf8caab5dd2e

#s.9UTXZAUNLaE7q9HCGvAbLSlq

#!/bin/bash

# Remove this variable, it should ve an environment variable
VAULT_APP=
VAULT_ADDR=
VAULT_PWD=
VAULT_NAMESPACE=

if ! command -v curl >/dev/null 2>&1 ; then
    echo "alert: command curl not found, please install the package"
    exit 1
fi

if ! command -v jq >/dev/null 2>&1 ; then
    echo "alert: command jq not found, please install the package"
    exit 1
fi

if ! command -v vault >/dev/null 2>&1 ; then
    echo "alert: command vault not found, please install the package"
    exit 1
fi

# Login into Vault
VAULT_TOKEN=$(curl -s -k -H "X-Vault-Namespace: ${VAULT_NAMESPACE}" --request POST --data '{"password": "${VAULT_PWD}"}' ${VAULT_ADDR}/v1/auth/ldap/login/${VAULT_USER} | jq .auth.client_token | sed -e 's/^"//' -e 's/"$//')
export ${VAULT_TOKEN}

# Obtain app credentials
export VAULT_NAMESPACE=peru-it/pa
ROLE_ID=$(vault read -field="role_id" auth/approle/role/${VAULT_APP}/role-id)
SECRET_ID=$(vault write -field="secret_id" -f auth/approle/role/${VAULT_APP}/secret-id)

# Obtain app token
APP_TOKEN=$(vault write -field="token" auth/approle/login role_id=${ROLE_ID} secret_id=${SECRET_ID})

#docker secret create my_secret_data ${APP_TOKEN}