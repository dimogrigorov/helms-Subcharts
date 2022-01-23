FROM nexus.secure.ifao.net:8443/mom-release-docker/openjdk:8-jdk-alpine

#since the openssl is required for the pub-prv key file generation,
#alpine doesnt support openssl directly, so using libressl packages
RUN echo -e "http://nl.alpinelinux.org/alpine/v3.14/main\nhttp://nl.alpinelinux.org/alpine/v3.14/community" > /etc/apk/repositories
RUN apk update && \
    apk add bash ca-certificates libressl libressl-dev --no-cache
RUN update-ca-certificates

ENV ENV_CONF=dev
COPY entrypoint.sh /opt/entrypoint.sh
#copy the file to generate the encryption
COPY scripts/securityKeyFile.sh /opt/securityKeyFile.sh
RUN chmod +x /opt/securityKeyFile.sh

COPY target/ccbd-*[^s].jar /opt/spring/lib/ccbd-latest.jar
RUN chmod -R 777 /opt/spring/lib

RUN mkdir /opt/spring/logs && \
    chmod 777 /opt/spring/logs
CMD [ "sh", "/opt/entrypoint.sh" ]
