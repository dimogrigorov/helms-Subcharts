 The project is fork of [mongodb-repliaset](https://github.com/helm/charts/tree/master/stable/mongodb-replicaset) - helm chart with updated MongoDB version to 4.4.2 (as of writing the official helm chart is using MongoDB 3.6). Here we will cover only our modifications. For detailed information about the project refer to the Original README available [here](README-orig.md)

# Requirements

* Kubernetes cluster 1.9+
* Helm v3

# Notes

Using the values from the values-new.yaml file the chart will start mongodb with:

* 1 replica. To start a cluster with more instances set "replicas:" to the desured number in values-new.yaml (always use odd number of replicase).
* TLS enabled, but will allow clients without certificates.
* Disabled persistence. It can be enabled by changing "PersistentVolume"  "enabled" to "true" in values-new.yaml.
* Enabled authentication. The login details for the admin user are defined in the values-new.yaml file.
* Disabled monitoring. The chart includes mongodb-exporter. To enable it set "metric" "enabled" to "true"  in values-new.yaml.

 Before installing the chart create kubernetes registry secret for nexus.secure.ifao.net:9343 named "nexus".

 ```sh
kubectl create secret docker-registry nexus --docker-server=nexus.secure.ifao.net:9343 --docker-username=USER --docker-password=PASS
 ```

# Installation

 ```sh
git clone https://repository.secure.ifao.net:7443/scm/mom/mongodb.git
helm install mongodb-replicaset mongodb --namespace mongodb --values values-new.yaml
```

# Extras

The project includes mongodb proxy and mongo-express deployments with service exposed on every node.

* The proxy is small script checking every 2 seconds which is the current mongodb primary, if it is different then the last check it will update the proxy service selector with the pod of the primary. The proxy deployment include RBAC role to allow access to the services in the deployed namespace. The Dockerfile and service update script are in the mongodb-proxy folder. 
  To install it, first if the mongodb servicename is correct in mongodb-proxy-service.yaml. The following variables should be defined in the mongodb-proxy.yaml before creating the proxy:

```sh
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

#Installation
kubectl create -f mongodb-proxy-service.yaml
kubectl create -f mongodb-proxy.yaml
```

* Mongo-express is web UI for mongodb: <https://github.com/mongo-express/mongo-express> . We are using custom config because of the TLS, it is added in custom image. The Docker file and config are in the mongo-express folder. 
  To install it update the environment variables in mongo-express.yaml and run:

```sh
kubectl create -f mongo-express.yaml 
```
  
# Wrning

The values-pvc.yaml and values-pvc-new.yaml files are with predefined TLS and admin login credentials and replication key for easy deployment, however, it is good idea to replace the values with your own.

# ToDo

Add mongodb-proxy to the chart templates. Add couple of checks in the check script.