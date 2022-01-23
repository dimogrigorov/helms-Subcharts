### Helm chart for notify-app deployment on OCP ####

# Prerequisites
## You need to issue or generate certificates in advance.


# **** - public part of certificate
# **** - private key
# **** - public part of CA issuer.

export keystore_pass="*****CHOOSE YOUR KEYSTORE PASS"
# the namespcace that you will deploy to
export namespace=ccbd
export notify_server_keystore=notify.p12

cat notify.crt ../root-ca/certs/ca.crt> notify-server-all.crt
openssl pkcs12 -export -in notify-server-all.crt -inkey notify.key -passout pass:${keystore_pass} -name shared > ${notify_server_keystore}

## Create required secrets
export ssl_keycloak_truststore_password="*****CHOOSE YOUR KEYCLOAK TRUSTORE PASS"
export ssl_cloud_config_truststore_password="*****CHOOSE YOUR CLOUD CONFIG PASSWORD"
export keycloak_client_secret="*****GET YOUR CLIENT SECRET FROM KEYCLOAK"

kubectl create secret generic notify-master-keystore --from-file=./cert_keystore/${notify_server_keystore} -n ${namespace}

kubectl create secret generic ssl.keycloak.truststore-password  --from-literal=ssl-keycloak-truststore-password=${ssl_keycloak_truststore_password} -n ${namespace}
kubectl create secret generic ssl.cloud-config.truststore-password --from-literal=ssl-cloud-config-truststore-password=${ssl_cloud_config_truststore_password} -n ${namespace}
kubectl create secret generic spring.security.oauth2.client.registration.keycloak.client-secret --from-literal=keycloak-client-secret=${keycloak_client_secret} -n ${namespace}


# Helm chart configurable values

------ Value ---------                                               |    ---- Default ----
autoscaling.enabled                                                  | false
autoscaling.replicaCount                                             | 1
                                                                     |
env.logging.file.path                                                | /var/log/notify
env.spring.cloud.config.uri                                          | "https://config-server.config:8888/"
env.spring.profiles.active                                           | test
env.spring.security.oauth2.client.provider.keycloak.token-uri        | "https://keycloak-dip.apps.openshift.sofia.ifao.net/auth/realms/cytric"
env.spring.security.oauth2.client.registration.keycloak.client-id    | notify
env.ssl.cloud-config.truststore                                      | "file:/opt/truststore/mom.p12"
env.ssl.cloud-config.truststore-password                             | Amadeus06
env.ssl.keycloak.truststore                                          | "file:/opt/truststore/mom.p12"
env.ssl.keycloak.truststore-password                                 | Amadeus06
                                                                     |
filebeat.image                                                       | "docker.elastic.co/beats/filebeat:6.8.13"
filebeat.resources.limits.cpu                                        | 100m
filebeat.resources.limits.memory                                     | 100Mi
filebeat.resources.requests.cpu                                      | 100m
filebeat.resources.requests.memory                                   | 100Mi
                                                                     |
fullnameOverride                                                     | notify-master
                                                                     |
image                                                                | "nexus.secure.ifao.net:9343/notify-master"
imageTag                                                             | 21
imagePullPolicy                                                      | Always
imagePullSecrets                                                     | {"name=nexus"} 
podSecurityContext                                                   | <nil>
                                                                     |
resources.limits.cpu                                                 | 1
resources.limits.memory                                              | 5012Mi
resources.requests.cpu                                               | 1
resources.requests.memory                                            | 128Mi
                                                                     |
securityContext                                                      | <nil>
service.port                                                         | 8082
service.type                                                         | ClusterIP
                                                                     |
serviceAccount.annotations                                           | <nil>
serviceAccount.create                                                | true
serviceAccount.name                                                  | filebeat
                                                                     |
strategy.rollingUpdate.maxSurge                                      | 50%
strategy.rollingUpdate.maxUnavailable                                | 50%
strategy.type                                                        | RollingUpdate
TBD:
volumeMounts:
  -
    mountPath: /opt/truststore
    name: mom
    readOnly: true
  -
    mountPath: /opt/keystore
    name: notify-keystore
    readOnly: true
  -
    mountPath: /var/run/secrets/tokens
    name: sa-token
    readOnly: true false

# Dry-run installation
helm install --dry-run --debug notify-master ./notify-helm/ -n ccbd
# Default installation
helm install notify-master ./notify-helm/ -n ccbd
# Helm custom installation
TBD
# Helm deployment removal
helm delete notify-master -n ccbd
# Jenkins pipeline examplet
TBD
