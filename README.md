# k8s-backup
Kubernetes Backup solution by exporting all k8s-components into YAML files and Uploading them to S3 Bucket

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
