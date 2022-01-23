#!/bin/sh

CHECK_INTERVAL=${CHECK_INTERVAL:-60}
CONFIG_SERVER_URL=${CONFIG_SERVER_URL:-"https://localhost:8888/monitor"}
REFRESH_ON_CHANGE=${REFRESH_ON_CHANGE:-false}
INITIAL_DELAY=${INITIAL_DELAY:-300}
script_name="refresh hook"
KEYCLOAK_CLIENT_ID=$(echo keycloak.resource | awk '{print ENVIRON[$1]}')
KEYCLOAK_CLIENT_SECRET=$(echo keycloak.credentials.secret| awk '{print ENVIRON[$1]}')
kc_URL_Head=$(echo keycloak.auth-server-url | awk '{print ENVIRON[$1]}')
kc_URL_Head=$([[ $kc_URL_Head =~  .*/$ ]] && echo "$kc_URL_Head" || echo "$kc_URL_Head/")
kc_Realm=$(echo keycloak.realm | awk '{print ENVIRON[$1]}')

KEYCLOAK_URL="${kc_URL_Head}realms/${kc_Realm}/protocol/openid-connect/token"


log() {
    local msg="$1"
    local timestamp
    timestamp=$( date +"%F %T")
    echo "${timestamp}      INFO  [$script_name] $msg"
}

get_keycloak_token() {
  export ACCESS_TOKEN=$(curl -s -k -X POST "$KEYCLOAK_URL" \
                            -H "Content-Type: application/x-www-form-urlencoded" \
                            -d "client_id=${KEYCLOAK_CLIENT_ID}" \
                            -d "client_secret=${KEYCLOAK_CLIENT_SECRET}" \
                            -d 'scope=openid' \
                            -d 'grant_type=client_credentials'| jq -r '.access_token')
}

web_hook() {
    log "Triggering bus refresh"
    curl -s --max-time 50 -k -X POST "${CONFIG_SERVER_URL}" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "X-Event-Key: repo:push" \
    -H "X-Hook-UUID: webhook-uuid" \
    -d '{"push": {"changes": []} }' # 2> /dev/null
}

refresh_if_change() {

    sleep "${INITIAL_DELAY}"
    cd /tmp/config-repo-* || exit
    web_hook
    echo "https://${bitbucket_user}:${bitbucket_pass}@$(printenv | grep bitbucket_url | cut -d "/" -f3)" >~/.git-credentials
    git config credential.helper store


    while true; do
        sleep "${CHECK_INTERVAL}"
        CHECK_FOR_CHANGE=$(git pull --dry-run 2>&1 | grep master | grep "..")
        if [[ -n "$CHECK_FOR_CHANGE" ]]; then
            log "Update Detected"
            get_keycloak_token
            web_hook
        fi
    done
}

check_if_first_pod() {
    pod_number=$(hostname |rev|cut -d "-" -f1 |rev)
    if [[ "$pod_number" == 0 ]];then
        log "This is the first pod in the stateful set."
        log "Starting auto config refresh script"
        refresh_if_change
    fi
}

log "Using repository ${bitbucket_url}"

if [[ "$REFRESH_ON_CHANGE" == "true" ]]; then
    log "Refresh on change enabled"
    log "Config server will check for update every $CHECK_INTERVAL"
    check_if_first_pod
fi
