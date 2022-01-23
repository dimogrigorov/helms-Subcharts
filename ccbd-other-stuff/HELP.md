# Some useful commands

### maven

* mvnw clean install -DskipTests=true
* mvnw clean install -Dmaven.wagon.http.ssl.insecure=true  (in case SSLhandshake exception)
* mvn surefire-report:report
* mvn site

### Run application
1. Via jar file
* java -jar ccbd-latest.jar --spring.profiles.active=dev
2. On docker
* mvn clean spring-boot:build-image -DskipTests=true
* docker run -it ccbd:latest -p 8080:8080
3. On minikube (Keycloak integration not yet working in minikube environment)
* mvn clean spring-boot:build-image -DskipTests=true -Dspring-boot.build-image.imageName=nexus.secure.ifao.net:9343/ccbd:latest
* docker push nexus.secure.ifao.net:9343/ccbd:latest
* minikube start
* helm install rabbitmq-test rabbitmq --values rabbitmq\values-new.yaml  (contact system admin for yaml)
* helm install mongodb-test mongodb --values mongodb\values-new.yaml    (contact system admin for yaml)
* kubectl create -f k8s.yml
* kubectl expose pod/<ccbd-podname> --type="NodePort" --port=8080
* minikube service ccbd --url

### How to setup dev environment
* git clone cytric_dummy
* cd ccbd/rabbitmq_admin && docker build -t rabbitmq_admin:latest .
* cd ccbd/mongo_admin && docker build -t mongo:local .
* cd ccbd && mvnw clean install -DskipTests=true
* docker-compose.exe -f docker-compose-local.yml up   (just exposing 6379 wont work, if ccbd is started outside docker, use ports)
* mvnw spring-boot:run -Dspring-boot.run.profiles=dev -Dspring.systemConfig.location=C:\Users\wjose\workspace\ccbd\src\main\resources\
* cd ../cytric-simulator-for-ccbd && mvnw spring-boot:run
* http://localhost:18080/publish - test performance
* http://localhost:18080/publish?type=ccbd - sample json

### Mongo shell

* Windows has firewall issues in sharing C drive. Hence copy db scripts and built a mongo:local image
* docker run -it --rm --network ccbd_default mongo:local   # run another container for mongo shell
* mongo --host mongo -u admin -p <pwd> -authenticationDatabase admin    # connect to actual db container
* docker run -it --rm --network ccbd_default mongo:local mongo --host mongo -u devops -p Amadeus06 ccbd
* docker run -it --rm --network host mongo:local mongo --host localhost -u admin -p secret --authenticationDatabase admin
* docker run -it --rm mongo:local mongo --ssl --sslAllowInvalidCertificates --sslAllowInvalidHostnames mongodb://admin:secret@192.168.0.15:32143/
  admin?ssl=true
* docker run -it --rm  --network host mongo:local mongo --quiet --ssl --sslAllowInvalidHostnames -u admin -p secret "mongodb://mongodb-proxy-tne-c
  cbd.nce2.paas.amadeus.net:443/admin" --sslAllowInvalidCertificates
* docker run -it --rm --network host mongo:local mongo --host 10.69.179.213:7008 --ssl --sslAllowInvalidCertificates  -u admin -p secret --authen
  ticationDatabase admin

### Add SSL certificate to JDK

* open CMD as admin
* keytool -import -noprompt -trustcacerts -alias mongodb -keystore "C:\Program Files\Java\jdk1.8.0_231\jre\lib\security\cacerts" -file C:\Users\wjose\Desktop\mongodb.cer

### Docker-filesharing in windows
* Powershell as administrator:: netsh advfirewall firewall set rule group="File and Printer Sharing over SMBDirect" new enable=Yes
* Network&Sharing Center->vEthernet DockerNAT->Properties->File & Printer Sharing for microsoft networks (turn on & off)
* Docker settings->sharing->select drive->reset credentials (if required)->Apply

### Actuator refresh endpoint

* curl -H "Content-Type: application/json" --request POST http://localhost:8080/ccbd/actuator/refresh

### Demo external interface
docker run --rm --name telefonica1 --network ccbd_default -it -p 8091:8091 extapp
docker run --rm --name telefonica2 --network ccbd_default -it -p 8092:8091 extapp
docker run --rm --name bosch --network ccbd_default -it -p 8093:8091 extapp
docker run --rm --name itelya --network ccbd_default -it -p 8094:8091 extapp
docker run --rm --name daimler --network ccbd_default -it -p 8095:8091 extapp


### NFR tasks

* Ensure reconnecting to RabbitMQ/mongo instance even if it gets restarted during ccbd process
    * Not guaranteed (but yes, by default). Rather cCBD updates k8s probe and prometheus monitoring will decide to restart the instance or not
* actuator metrics on Prometheus - done
* ccbd logs - json standardization and storing in ELK - done
* enable/create mongodb metrics - done outside the cCBD scope 
* custom ccbd metrics via micrometer - done
* ccbd Alerts via alertmanager - not in the scope of cCBD, should be done outside
* Refresh parameters in runtime (for eg: logging level) - done
* Secure actuator endpoints - done
* LRU cache for statistics (see if it can be handled at prometheus)
    * This will not be implemented in cCBD rather create a dashboard in grafana using the metrics 
* Gracefully handle config server outage (during startup/runtime), mongo outage(startup/runtime), rabbitmq (startup/runtime)
    * If config server is not available in startup, cCBD will use embedded configuration
    * Mongo is mandatory for cCBD to start, but it can handle outage when the process is up. But remember cCBD cannot do any job without database
    * RabbitMQ connector will retry forever in case the service is not available
* Recreate scheduled application tasks in runtime - done
    * Cancel only completed tasks - on Thread level
        * Yet to perform more tests. As cCBD uses the built in capabilities, it was observed that spring waits for the older process 
     to complete before removing the old executor. But new executor starts immediately  

### TO DO

* Validate 'timed' metric value using timer at start and end
* 1 hour statistics
* Unit tests, integration tests
* https communication to ext, cytric, rmq, mongo
* daily export of booking events to ftp
* Clean up/package refresh
* Clean up metrics
* git hook for auto refresh
* Mongo advanced - locks/txns/acid
* rmq - direct to fan-out, to support expense
* REST apis for entity CRUD
* Sync application.yml to external git
* Review reactive code with experts

### Demo
1. visit Docker-compose
    1.1 RMQ admin portal
    1.2 RMQ admin container
    1.3 Prometheus config & metrics
    1.4 Alert manager config
    1.5 Telegram chatbot
    1.6 Kibana logs, logstash and logback
    1.7 ccbd actuator endpoints
    1.8 Config server & demo
2. cytric simulator, publisher & api
3. Ext system simulator, api and status
4. ccbd overview
    4.1 subscribers
    4.2 repositories
    4.3 reactor
    4.4 exception handling
    4.5 retry

### Design choices
* MongoDB unavailable: CCBD send NACK to RabbitMQ, after a configurable mongo connect timeout. 
This will result in RabbitMQ repeatedly sending the NACK messages to CCBD. 
No other treatment to MongoDB timeout, which means scheduled tasks will continue to flood the log with exception
* RabbitMQ unavailable: SpringAMQP has an inbuilt retry mechanism and does not support RabbitMQ specifics about retry.
In case RabbitMQ throws authenticationfailureexception (ACCESS_REFUSED) due to delayed user creation,
 RabbitMQConfiguration::simpleRabbitListenerContainerFactory makes it non fatal.
* In case RabbitMQ resources unavailable: CCBD as a listener declare queues and exchanges if it does not exist, also bind queues (though it is not required). 
 It is the publisher who should declare these resources.
 

### SSL

* csplit -f individual- [your-pem].pem '/-----BEGIN RSA PRIVATE KEY-----/' '{*}'
* keytool -list -v -keystore [keystore/truststore].p12
* keytool -list -rfc -keystore [keystore/truststore] > [your-certificate].crt
* keytool -genkeypair -alias [give-a-suitable-name-for-cert-to-identify] -keyalg RSA -keysize 2048 -storetype PKCS12 -keystore [keystore/truststore].p12 -validity 3650
* keytool -import -alias [give-a-suitable-name-for-cert-to-identify] -file [pem-file].pem -keystore [keystore/truststore].p12
* keytool -import -alias [give-a-suitable-name-for-cert-to-identify] -file [certificate].crt -keystore [keystore/truststore].p12
*
* keycloak docker cert in - /opt/jboss/keycloak/standalone/configuration

### K8S

* kubectl create secret docker-registry nexus --docker-server=nexus.secure.ifao.net:9343 --docker-username=[contact_devops] --docker-password=[contact_devops]
* helm install keycloak keycloak
* helm ls 

* kubectl expose pod/service podname/servicename --type "NodePort" --port 5671/27017

* minikube service mongodb-test-mongodb-ha --url
* kubectl port-forward rabbitmq-test-rabbitmq-ha-0 32524:5671