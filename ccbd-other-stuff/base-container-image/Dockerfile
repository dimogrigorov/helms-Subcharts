#This is the base image used by the applicaiton to deploy. It is utilizing the alpine base image, and installing openjdk:1.8.0.302
#current latest alpine version is 3.14

FROM amd64/alpine:3.14
CMD ["/bin/sh"]
ENV LANG=C.UTF-8

RUN { echo '#!/bin/sh'; 	echo 'set -e'; 	echo; echo 'dirname "$(dirname "$(readlink -f "$(which javac || which java)")")"'; }  > /usr/local/bin/docker-java-home 	&& chmod +x /usr/local/bin/docker-java-home

ENV JAVA_HOME=/usr/lib/jvm/java-1.8-openjdk
ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/lib/jvm/java-1.8-openjdk/jre/bin:/usr/lib/jvm/java-1.8-openjdk/bin
ENV JAVA_VERSION=8u302
ENV JAVA_ALPINE_VERSION=8.302.08-r2

#since 3.15 is not available in the dockerhub at the time, we are editing the base image repo to point to latest version at the time of build
RUN sed -i 's/3.14/3.15/g' /etc/apk/repositories

RUN set -x && apk add --no-cache openjdk8="$JAVA_ALPINE_VERSION" && [ "$JAVA_HOME" = "$(docker-java-home)" ]

RUN apk update