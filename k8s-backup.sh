#!/bin/bash
###########

# Global Configurations
#======================
BACKUP_DIR=/usr/local/backup
AWS_CMD=/usr/bin/aws
TIME_STAMP=$(date +%Y-%m-%d_%H-%M)
######################
function get_secret {
  kubectl get secret -n ${1} -o=yaml --export --field-selector type!=kubernetes.io/service-account-token | sed -e '/kubectl\.kubernetes\.io\/last\-applied\-configuration:/,+1d' -e '/resourceVersion: "[0-9]\+"/d' -e '/uid: [a-z0-9-]\+/d' -e '/selfLink: [a-z0-9A-Z/]\+/d'
}

function get_configmap {
  kubectl get configmap -n ${1} -o=yaml --export | sed -e '/kubectl\.kubernetes\.io\/last\-applied\-configuration:/,+1d' -e '/resourceVersion: "[0-9]\+"/d' -e '/uid: [a-z0-9-]\+/d' -e '/selfLink: [a-z0-9A-Z/]\+/d'
}

function get_ingress {
  kubectl get ing -n ${1} -o=yaml --export | sed -e '/kubectl\.kubernetes\.io\/last\-applied\-configuration:/,+1d' -e '/status:/,+2d' -e '/\- ip: \([0-9]\{1,3\}\.\)\{3\}[0-9]\{1,3\}/d' -e '/resourceVersion: "[0-9]\+"/d' -e '/uid: [a-z0-9-]\+/d' -e '/selfLink: [a-z0-9A-Z/]\+/d'
}

function get_service {
  kubectl get service -n ${1} -o=yaml --export | sed -e '/ownerReferences:/,+5d' -e '/resourceVersion: "[0-9]\+"/d' -e '/uid: [a-z0-9-]\+/d' -e '/selfLink: [a-z0-9A-Z/]\+/d' -e '/clusterIP: \([0-9]\{1,3\}\.\)\{3\}[0-9]\{1,3\}/d' 
}

function get_deployment {
  kubectl get deployment -n ${1} -o=yaml --export | sed -e '/deployment\.kubernetes\.io\/revision: "[0-9]\+"/d' -e '/kubectl\.kubernetes\.io\/last\-applied\-configuration:/,+1d' -e '/resourceVersion: "[0-9]\+"/d' -e '/uid: [a-z0-9-]\+/d' -e '/selfLink: [a-z0-9A-Z/]\+/d' -e '/status:/,+18d'
}

function get_cronjob {
  kubectl get cronjob -n ${1} -o=yaml --export | sed -e '/kubectl\.kubernetes\.io\/last\-applied\-configuration:/,+1d' -e '/status:/,+1d' -e '/resourceVersion: "[0-9]\+"/d' -e '/uid: [a-z0-9-]\+/d' -e '/selfLink: [a-z0-9A-Z/]\+/d'
}

function get_pvc {
  kubectl get pvc -n ${1} -o=yaml --export | sed -e '/control\-plane\.alpha\.kubernetes\.io\/leader\:/d' -e '/resourceVersion: "[0-9]\+"/d' -e '/uid: [a-z0-9-]\+/d' -e '/selfLink: [a-z0-9A-Z/]\+/d'
}

function get_pv {
  for pvolume in `kubectl get pvc -n ${1} -o=custom-columns=:.spec.volumeName` 
  do
     kubectl get pv -o=yaml --export --field-selector metadata.name=${pvolume} | sed -e '/resourceVersion: "[0-9]\+"/d' -e '/uid: [a-z0-9-]\+/d' -e '/selfLink: [a-z0-9A-Z/]\+/d'
  done
}

function export_ns {
  mkdir -p ${BACKUP_DIR}/${CLUSTER_NAME}/
  cd ${BACKUP_DIR}/${CLUSTER_NAME}/
  for namespace in `kubectl get namespaces --no-headers=true | awk '{ print $1 }' | grep -v -e "cattle-system" -e "kube-system" -e "kube-public"`
  do
     echo "Namespace: $namespace"
     echo "+++++++++++++++++++++++++"
     mkdir -p $namespace

     for object_kind in configmap ingress service secret deployment cronjob pvc
     do
       if kubectl get ${object_kind} -n ${namespace} 2>&1 | grep "No resources" > /dev/null; then
         echo "No resources found for ${object_kind} in ${namespace}"
       else
         get_${object_kind} ${namespace} > ${namespace}/${object_kind}.${namespace}.yaml &&  echo "${object_kind}.${namespace}";
         
         if [ ${object_kind} = "pvc" ]; then
           get_pv ${namespace} > ${namespace}/pv.${namespace}.yaml &&  echo "pv.${namespace}";
         fi
       fi
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

###########
export_ns
archive_ns
upload_backup_to_s3
