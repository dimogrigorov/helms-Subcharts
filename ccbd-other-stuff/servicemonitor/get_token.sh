#!/bin/sh

HOSTNAME=${KC_HOSTNAME:-10.69.179.213:7006}
REALM_NAME=${REALM_NAME:-cytricNG}
USERNAME=${USERNAME:-kalin}
KEYCLOAK_URL=https://$HOSTNAME/auth/realms/$REALM_NAME/protocol/openid-connect/token
CLIENT_ID=${CLIENT_ID:-admin-cli}
PASSWORD=${PASSWORD}
GRANT_TYPE=${GRANT_TYPE:-password}

export TOKEN=$(curl -k -X POST "$KEYCLOAK_URL" \
	 -H "Content-Type: application/x-www-form-urlencoded" \
	 -d "username=$USERNAME" \
	 -d "password=$PASSWORD" \
	 -d "grant_type=$GRANT_TYPE" \
	 -d "client_id=$CLIENT_ID" | jq -r '.access_token')


if [[ $(echo $TOKEN) != 'null' ]]; then
	    kubectl delete secret ccbd-servicemonitor-token 2>/dev/null
	    kubectl create secret generic ccbd-servicemonitor-token --from-literal=token="$TOKEN"
fi


