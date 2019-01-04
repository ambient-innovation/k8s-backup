# k8s-backup
Kubernetes backup solution by exporting all k8s-components into YAML files and Uploading them to S3 Bucket archived and encrypted with a password.

- The following K8s components/objects are extracted:
  - Secrets
  - Config Maps
  - Deployments
  - Services
  - Ingress
  - Persistent Volumes
  - Cronjobs

## Usage
```
docker run -it \
-e S3_BUCKET=my-s3-bucket-name \
-e AWS_ACCESS_KEY_ID=my-aws-access-key \
-e AWS_SECRET_ACCESS_KEY=my-aws-secret-key \
-e CLUSTER_NAME=my-cluster-name \
-e KUBE_ARCHIVE_PW=my-secret-password \
-v path-to-kube-config-dir:/root/.kube \
k8s-backup:latest
```

To decrypt the backup/archive run `openssl enc -aes-256-cbc -d -in name.tar.gz.enc | tar xz`.

## Development

This project is hosted at https://github.com/ambient-innovation/k8s-backup

The docker image is hosted on dockerhub at https://hub.docker.com/r/ambientinnovation/k8s-backup.

To make changes, proceed as follows:

1. Make your changes to the code, just push to the repo. It is configured as automated build. The branch
"master" will receive the tag "latest" and each Git Tag will create a corresponding docker tag.
