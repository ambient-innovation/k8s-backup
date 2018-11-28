# k8s-backup
Kubernetes backup solution by exporting all k8s-components into YAML files and Uploading them to S3 Bucket.
It will encrypt these backups and upload them to an S3 bucket.

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

To decrypt the backup run `openssl enc -aes-256-cbc -d -in name.tar.gz.enc | tar xz`.
