# Helm chart for mongodb-proxy deployment on OCP
The mongodb-proxy app are checking which is the current master node from mongodb-replicaset and patch the service to point to it.

## Prerequisites
mongodb-replicaset must be deployed in same namespace.
1. The chart by default is using mongodb-replicaset secret=mongodb-cred for "root" user authentication against mongodb with key=mongodb-root-password.
2. The chart by default is using mongodb-replicaset secret=mongodb-replicaset-ca for TLS connection to mongodb (key=mongodb-ca-cert and key=mongodb-ca-key)

Note: You can create own secrets with same keys and provide it to helm chart as values.yaml or set them during deployment.

## Helm chart configurable values

------ Value ---------                        |    ---- Default ----
replicaCount                                  |         1
image.repository                              | nexus.secure.ifao.net:9343/mongodb-proxy
image.pullPolicy                              | IfNotPresent
image.tag                                     | latest
imagePullSecrets                              | <nil>
nameOverride                                  | <nil>
fullnameOverride                              | <nil>
podAnnotations                                | <nil>
podSecurityContext                            | <nil>
securityContext                               | <nil>
rbac.create                                   | true
rbac.name                                     | role-mongodb-proxy
serviceAccount.create                         | true
serviceAccount.name                           | mongodb-proxy-updater
tls.existingSecret                            | mongodb-replicaset-ca (secret name with key=mongodb-ca-cert and key=mongodb-ca-key)
auth.mongodbAdminUser                         | root
auth.mongodbSecret                            | mongodb-cred (secret name with key=mongodb-root-password)
service.type                                  | ClusterIP
service.port                                  | 27017
resources.limits.cpu                          |         1
resources.limits.memory                       |         1Gi
resources.requests.cpu                        |        500m
resources.requests.memory                     |        512Mi
env.mongodbService                            | mongodb-replicaset-headless
nodeSelector                                  | <nil>
tolerations                                   | <nil>
affinity                                      | <nil>

# Installation
helm upgrade mongodb-proxy mongodb-proxy-0.1.0.tgz --install --wait --timeout 5m --values ${values.yaml}
