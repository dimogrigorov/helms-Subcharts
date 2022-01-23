### Helm chart for cCBD deployment on OCP ####

# Prerequisites
## You need to issue or generate certificates in advance.
- ccbd.crt - public part of certificate
- ccbd.key - private key
- Root CA - public part of CA issuer.

export CCBD_SERVER_KEYSTORE="ccbd.p12"
export MOM_TRUST_KEYSTORE="mom.p12"
export KEYSTORE_PASS="choose some pass"

cat ccbd.crt ifao-root-ca.pem > ccbd-server-all
openssl pkcs12 -export -in ccbd-server-all -inkey ccbd.key -passout pass:${KEYSTORE_PASS} -name shared > ${CCBD_SERVER_KEYSTORE}
keytool -import -noprompt -trustcacerts -alias ifao-root-ca -keystore ${MOM_TRUST_KEYSTORE} -file ifao-root-ca.pem  -storepass ${KEYSTORE_PASS} -storetype PKCS12 -validity 5000 -keyalg RSA -keysize 2048

## Create required secrets
export KEYCLOAK_SECRET="Get it from keycloak app"

oc create secret generic ccbd-keystore --from-file=${CCBD_SERVER_KEYSTORE}  --dry-run=client -o yaml | oc apply -f - 
oc create secret generic mom-truststore --from-file=${MOM_TRUST_KEYSTORE} --dry-run=client -o yaml | oc apply -f - 
oc create secret generic ccbd-private-key --from-file=ccbd.key --dry-run=client -o yaml | oc apply -f -
oc create secret generic ccbd-cred --from-literal=keycloak=${KEYCLOAK_SECRET} --from-literal=truststore-password=${KEYSTORE_PASS} --dry-run=client -o yaml | oc apply -f -

## Create required Config Maps.

oc create configmap obj-exchange-xsd --from-file=ObjectExchange4_final.xsd  --dry-run=client -o yaml | oc apply -f -
* Note: ObjectExchange4_final.xsd comming from cCBD "git" repo.

oc create configmap kat-keystore --from-file=keystore-dev.jks --dry-run=client -o yaml | oc apply -f -
* Note: keystore-dev.jks needed for connection to KAT.

oc create configmap kat-trusted-keystore --from-file=keystoreTrusted.jks --dry-run=client -o yaml | oc apply -f -
* Note: kat-trusted-keystore public part of contain Security Manager CA.

oc create configmap ext-endpoints-truststore --from-file=external-system-truststore.p12 --dry-run=client -o yaml | oc apply -f -
* Note: Customer's Custom CAs.

# Helm chart configurable values

------ Value ---------                                                           |    ---- Default ----
affinity                                                                         | <nil>
                                                                                 |
autoscaling.enabled                                                              | false
autoscaling.maxReplicas                                                          | 4
autoscaling.minReplicas                                                          | 1
autoscaling.targetCPUUtilizationPercentage                                       | 80
autoscaling.targetMemoryUtilizationPercentage                                    | 80
                                                                                 |
env.JAVA_OPTS                                                                    | "-Xss256k -Xms1G -Xmx6G -XX:+UseG1GC -XX:MaxGCPauseMillis=2000 -XX:+OptimizeStringConcat -XX:+UseStringCache -XX:MaxHeapFreeRatio=70 -XX:+UseStringDeduplication"
env.spring.cloud.config.uri                                                      | "https://config-server.config:8888/"
env.spring.profiles.active                                                       | test
env.spring.security.oauth2.client.provider.keycloak.token-uri                    | "https://keycloak-dip.apps.openshift.sofia.ifao.net/auth/realms/cytricNG/protocol/openid-connect/token"
env.spring.security.oauth2.client.registration.keycloak.authorization-grant-type | client_credentials
env.spring.security.oauth2.client.registration.keycloak.client-id                | ccbd
env.ssl.cloud-config.truststore                                                  | "file:/opt/truststore/mom.p12"
env.ssl.keycloak.truststore                                                      | "file:/opt/truststore/mom.p12"
                                                                                 |
filebeat.image                                                                   | "docker.elastic.co/beats/filebeat:6.8.13"
filebeat.resources.limits.cpu                                                    | 100m
filebeat.resources.limits.memory                                                 | 100Mi
filebeat.resources.requests.cpu                                                  | 100m
filebeat.resources.requests.memory                                               | 100Mi
                                                                                 |
fullnameOverride                                                                 | "ccbd-master"
                                                                                 |
image.pullPolicy                                                                 | IfNotPresent
iamge.repository                                                                 | "nexus.secure.ifao.net:9343/ccbd-master"
image.tag                                                                        | "21.08.352"
imagePullSecrets                                                                 | {"name=nexus"}
ingress.annotations                                                              | {}
ingress.enabled                                                                  | false
TBD:
ingress.hosts:
    -
      host: chart-example.local
      paths: []
ingress.tls: []

nameOverride                                                                     | ""
nodeSelector                                                                     | <nil>
podAnnotations                                                                   | <nil>
podSecurityContext                                                               | <nil>
replicaCount                                                                     | 1
                                                                                 |
resources.limits.cpu                                                             | 4
resources.limits.memory                                                          | 8Gi
resources.requests.cpu                                                           | 1
resources.requests.memory                                                        | 1Gi
                                                                                 |
securityContext                                                                  | <nil>
                                                                                 |
serviceAccount.annotations                                                       | <nil>
serviceAccount.create                                                            | true
serviceAccount.name                                                              | filebeat
service.port                                                                     | 8080
service.type                                                                     | ClusterIP
TBD:
tolerations: []
TBD:
volumeMounts:
  -
    mountPath: /opt/private
    name: ccbd-private-key
    readOnly: true
  -
    mountPath: /opt/truststore
    name: mom
    readOnly: true
  -
    mountPath: /opt/keystore
    name: ccbd-keystore
    readOnly: true
  -
    mountPath: /opt/ext-trustore
    name: ext-trustore
    readOnly: true
  -
    mountPath: /opt/exchange
    name: obj-exchange
    readOnly: true
  -
    name: all-in-one
    mountPath: /opt/kat
    readOnly: true

# Dry-run Installation
helm install --dry-run --debug ccbdmaster ./ccbd-helm/ -n ccbd
# Default installation
helm install ccbdmaster ./ccbd-helm/ -n ccbd
# Helm deployment removal
helm delete ccbdmaster -n ccbd
# Helm custom installation                                                             
TBD 
# Jenkins pipeline example
https://repository.secure.ifao.net:7443/scm/its/ccbd-deployment.git
