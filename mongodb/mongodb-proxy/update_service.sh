#!/bin/bash


CHECK_INTERVAL=2    #seconds
SERVICE_NAME=${MNG_LB_SERVICE:=mongo-proxy}
MONGO_AUTH_DB=${MONGO_AUTH_DB:=admin}
MONGO_REPLICASET=${MONG_REPLICASET:=rs0}
MONGO_ADMIN_USER=${MONGO_ADMIN_USER:=admin}
MONGO_ADMIN_PASS=${MONGO_ADMIN_PASS:=secret}
MONGO_PORT=${MONGO_PORT:=27017}
MONGO_HOST=${MONGO_HOST:=mongodb-replicaset}
MONGO_PEM_KEY=${MONGO_PEM_KEY:=mongo.pem}
MONGO_CA_FILE=${MONGO_CA_FILE:=/ca-readonly/tls.crt}
script_name=${SERVICE_NAME}



log() {
    local msg="$1"
    local timestamp
    timestamp=$(date --iso-8601=seconds)
    echo "[$timestamp] [$script_name] $msg"
}


update_service() {
    #Check if the selector select in the service is the same as the primary retrieved from mongodb. If different patch the service
    if ! [[ -n "${PRIMARY_MONGO}" && "${PRIMARY_MONGO}" == "${SERVICE_MONGO}" ]]
    then
        
        patch_result=$(echo \'{\"spec\":{\"selector\":{\"statefulset.kubernetes.io/pod-name\": \"${PRIMARY_MONGO}\"}}}\' |xargs kubectl patch service ${SERVICE_NAME}  -p)
        log  "Updating service ${SERVICE_NAME} setting selector to ${PRIMARY_MONGO}"
        log  "$patch_result"
        SERVICE_MONGO="${PRIMARY_MONGO}"
        
    fi
}



main_loop() {
    while true
    do
        sleep $CHECK_INTERVAL
        PRIMARY_MONGO=$(timeout ${CHECK_INTERVAL} mongo --ssl --quiet -u ${MONGO_ADMIN_USER} -p ${MONGO_ADMIN_PASS} "mongodb://${MONGO_HOST}:${MONGO_PORT}/${MONGO_AUTH_DB}?replicaSet=${MONGO_REPLICASET}" --sslAllowInvalidCertificates  --sslAllowInvalidHostnames --sslCAFile ${MONGO_CA_FILE}  --eval 'db.isMaster().primary'  | cut -d ":" -f1 | grep mongo| cut -d "." -f1)
        
        update_service
        
    done
}

main_loop
