FROM openjdk:8-jdk-alpine as build_box
COPY src /opt/config-server/src
COPY mvnw /opt/config-server/
COPY .mvn /opt/config-server/.mvn
COPY pom.xml /opt/config-server/
RUN cd /opt/config-server/ && sh mvnw -Dmaven.wagon.http.ssl.insecure=true -Dmaven.wagon.http.ssl.allowall=true -Dmaven.wagon.http.ssl.ignore.validity.dates=true clean install  -DskipTests
RUN chgrp -R 0 /opt/config-server/target \
  && chmod -R g+rwX /opt/config-server/target

FROM openjdk:8-jdk-alpine
ENV HOME /opt/spring
RUN apk add git curl jq --no-cache
RUN mkdir /opt/spring \
  && chgrp -R 0 /opt/spring \
  && chmod -R g+rwX /opt/spring
COPY --from=build_box /opt/config-server/target/config*.jar /opt/spring/config-server.jar
COPY check_for_repo_change.sh /opt/spring/
COPY entrypoint.sh /opt/spring/entrypoint.sh
WORKDIR /opt/spring/
ENTRYPOINT ["sh", "./entrypoint.sh"]
