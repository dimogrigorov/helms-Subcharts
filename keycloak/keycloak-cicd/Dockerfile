FROM dockerhub.rnd.amadeus.net/docker-quay-io-remote/keycloak/keycloak:15.0.0

# Copy certificates and import them
COPY certificates/* /opt/certs/
USER root
RUN keytool -importcert -file /opt/certs/Trust_CA.cer -alias Trust_CA -cacerts -storepass changeit -noprompt
RUN keytool -importcert -file /opt/certs/ifao-root-ca.cer -alias ifao-root-ca -cacerts -storepass changeit -noprompt
RUN keytool -importcert -file /opt/certs/vizion-ca.cer -alias vizion-ca -cacerts -storepass changeit -noprompt
RUN keytool -importcert -file /opt/certs/cytric-sofia-ifao-net.cer -alias cytric-sofia-ifao-net -cacerts -storepass changeit -noprompt
USER 1000

# Copy the Oracle JDBC jar
COPY database/ojdbc8.jar /opt/jboss/keycloak/modules/system/layers/base/com/oracle/jdbc/main/driver/ojdbc.jar
# Replace semicolon to forward slash, this is the fix for the service connection issue
RUN sed -i -e 's/${env.DB_PORT:1521}:${env.DB_DATABASE:XE}/${env.DB_PORT:1521}\/${env.DB_DATABASE:XE}/g' /opt/jboss/tools/cli/databases/oracle/change-database.cli

# Copy the Open API and Cytric NG realms
COPY realms/*.json /opt/realms/

# Copy the Open API dependencies
COPY build/openapi/*.jar /opt/jboss/keycloak/standalone/deployments/
