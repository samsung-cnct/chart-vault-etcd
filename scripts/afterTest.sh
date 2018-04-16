#! /usr/local/bin/bash -ex
# setup kubectl
echo "Setting up kubectl"
wget https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl
chmod +x ./kubectl
mv ./kubectl /usr/local/bin/kubectl

# clean up the namespace
echo "Cleaning up namespace etcd-vault-${PIPELINE_BUILD_ID}"
kubectl delete namespace etcd-vault-${PIPELINE_BUILD_ID} || true