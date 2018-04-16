#! /usr/local/bin/bash -ex
# clean up the namespace
echo "Cleaning up namespace etcd-${PIPELINE_BUILD_ID}"
kubectl delete namespace etcd-vault-${PIPELINE_BUILD_ID} || true