FROM alpine:3.6
RUN apk --no-cache add curl jq
RUN curl https://storage.googleapis.com/kubernetes-release/release/v1.18.0/bin/linux/amd64/kubectl -o /usr/bin/kubectl -s && chmod +x /usr/bin/kubectl
COPY get_token.sh /
ENTRYPOINT ["sh","/get_token.sh"]

