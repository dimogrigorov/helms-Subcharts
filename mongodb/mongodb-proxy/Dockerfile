FROM ubuntu:18.04

RUN apt update -y && \
    apt install wget mongodb-clients -y && \
    wget https://storage.googleapis.com/kubernetes-release/release/v1.18.0/bin/linux/amd64/kubectl -O /usr/bin/kubectl && \
    chmod +x /usr/bin/kubectl && \
    rm -rf /var/lib/apt/lists/* && \
    ls /usr/bin/mongo* | grep -v "mongo$" |xargs rm  

COPY update_service.sh /update_service.sh
CMD [ "/update_service.sh" ]

