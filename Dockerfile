FROM alpine:latest
ENV TZ Europe/Berlin

WORKDIR /srv

RUN apk update && apk add --no-cache bash \
    tzdata less python3 curl mlocate groff openssl

RUN curl -O https://bootstrap.pypa.io/get-pip.py \
    && python3 get-pip.py \
    && rm -f get-pip.py

RUN cp /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN pip install awscli --upgrade
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.17.17/bin/linux/amd64/kubectl \
    && chmod +x kubectl && mv kubectl /usr/local/bin/kubectl \
    && mkdir -p /root/.kube
VOLUME ["/root/.kube"]

COPY k8s-backup.sh /usr/local/bin/k8s-backup.sh
RUN  chmod +x /usr/local/bin/k8s-backup.sh

ENTRYPOINT ["k8s-backup.sh"]
