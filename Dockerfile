FROM alpine:latest

WORKDIR /srv

RUN apk update && apk add --no-cache bash \
    tzdata groff less python curl mlocate groff openssl

RUN curl -O https://bootstrap.pypa.io/get-pip.py \
    && python get-pip.py \
    && rm -f get-pip.py

RUN pip install awscli --upgrade
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl \
    && chmod +x kubectl && mv kubectl /usr/local/bin/kubectl \
    && mkdir -p /root/.kube
VOLUME ["/root/.kube"]

COPY k8s-backup.sh /usr/local/bin/k8s-backup.sh
RUN  chmod +x /usr/local/bin/k8s-backup.sh

ENTRYPOINT ["k8s-backup.sh"]
