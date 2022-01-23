# Getting Started

### ENV variables

* keycloak.realm
* keycloak.resource
* keycloak.credentials.secret
* encrypt.key
* keycloak.auth-server-url
* server.ssl.enabled
* server.ssl.key-store
* server.ssl.key-store-password
* keycloak.truststore
* keycloak.truststore-password
* server.port


### Profile

1. Run dev profile by giving jvm arguments dev,native


### Installation
1. Generate keystore for config-server
   
     ```text
      keystore_pass=Amadeus06
      deployment_file=spring-cloud-config-statefulset.yaml 
      namespace=config
      rabbitmq_pass="rabbitmq_pass"
      rabbitmq_user="rabbitmq_user"
      config_server_keystore=config-server.p12
      keycloak_secret=22ac8b9c-1235-asdf-9b36-173c856be997  
      bitbucket_password="bit-bucketpass"
      bitbucket_user="config_server"
      main_truststore_pass="Amadeus06"
      encrypt_key="Alo3kdarWajkUAApeji5gsw" 
     ``` 
     Note: encrypt_key -The encryption key should long string, it will be used for the passwords encryption
           keycloak_secret - The client secret from keycloak
1. Create kubernetes secret with the keystore
     ```text  
      kubectl create secret generic config-server-keystore --from-file=./${config_server_keystore} -n ${namespace}
     ```
1. Create secret with the bitbucket user and password for config-server      
     ```text
      kubectl create secret generic bitbucket-creds --from-literal=bitbucket_user="${bitbucket_user}" --from-literal=bitbucket_pass="${bitbucket_password}" -n  ${namespace}
     ``` 
1. Create kubecretes secret with the password for the keystore and the encryption key for config-server.
     ```text
      kubectl create secret generic  config-server-secrets --from-literal=keystore_pass="${keystore_pass}"  --from-literal=encrypt_key="${encrypt_key}" -n  ${namespace}
     ```
1. If the root truststore is not created in the "Generate root truststore" step, it must be created now.       
     ```text
      kubectl create secret generic  main-truststore --from-literal=truststore_location='file:/opt/truststore/mom.p12' --from-literal=truststore_pass="${main_truststore_pass}" -n ${namespace}
     ``` 
1. Create kubernetes secret with the login details for rabbitmq.
     ```text
      kubectl create secret generic  rabbitmq-creds --from-literal=rabbitmq_user=${rabbitmq_user} --from-literal=rabbitmq_pass="${rabbitmq_pass}" -n ${namespace}
     ``` 
1. Create kubernetes secret with keycloak client secret.
     ```text 
      kubectl create secret generic  keycloak-secret --from-literal=keycloak_secret="$keycloak_secret" -n ${namespace}
     ```
1. Deploy config server
     ```text
     cp -pr ../../config-server/${deployment_file} ${deployment_file}
     kubectl create -f ${deployment_file} -n ${namespace}
     ```     
