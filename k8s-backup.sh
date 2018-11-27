#!/bin/bash
###########

# Global Configurations
#======================
BACKUP_DIR=/usr/local/backup
AWS_CMD=/usr/bin/aws
TIME_STAMP=$(date +%Y-%m-%d_%H-%M)

function export_ns {
  mkdir -p ${BACKUP_DIR}/${CLUSTER_NAME}/
  cd ${BACKUP_DIR}/${CLUSTER_NAME}/
  for namespace in `kubectl get namespaces | awk ' NR > 1 {print $1}'`
  do
     echo "Namespace: $namespace"
     echo "+++++++++++++++++++++++++"
     mkdir -p $namespace

     for object_kind in configmap ingress service secret deployment statefulset hpa job cronjob
     do
       for object_name in `kubectl get $object_kind -n ${namespace} 2>/dev/null | awk 'NR > 1 {print $1}' | grep -Ev 'service-account-token|default-token'`
       do
         kubectl get $object_kind -n ${namespace} -o=yaml --export > ${namespace}/${object_kind}.${object_name}.yaml;
         echo "${object_kind}.${object_name}";
       done
     done
     echo "+++++++++++++++++++++++++"
  done
}

###########################################################
## Archiving k8s data with password to upload it to AWS S3.
## This password is available on our password manager.
############################################################
function archive_ns {
  cd ${BACKUP_DIR}
  tar cz ${CLUSTER_NAME} | openssl enc -aes-256-cbc -e -k ${KUBE_ARCHIVE_PW} > ${BACKUP_DIR}/${CLUSTER_NAME}-${TIME_STAMP}.tar.gz.enc
}

# Upload Backups
#===============
function upload_backup_to_s3 {
  ${AWS_CMD} s3 cp ${BACKUP_DIR}/${CLUSTER_NAME}-${TIME_STAMP}.tar.gz.enc s3://${S3_BUCKET}/${CLUSTER_NAME}/
  if [ $? -eq 0 ]; then
    echo "${CLUSTER_NAME}-${TIME_STAMP}.tar.gz.enc is successfully uploaded"
    rm -rf ${BACKUP_DIR}/${CLUSTER_NAME} ${BACKUP_DIR}/k8s-data-${TIME_STAMP}.tar.gz.enc
  else
    echo "${CLUSTER_NAME}-${TIME_STAMP}.tar.gz.enc failed to be uploaded"
  fi
}


export_ns
archive_ns
upload_backup_to_s3
