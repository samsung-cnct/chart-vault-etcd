#! /usr/local/bin/bash -ex
# setup golang
echo "Setting up golang"
wget https://redirector.gvt1.com/edgedl/go/go1.9.2.linux-amd64.tar.gz
tar -C /usr/local -xzf go1.9.2.linux-amd64.tar.gz
mkdir /go
export PATH=$PATH:/usr/local/go/bin:/go/bin
export GOPATH=/go
mkdir /lib64 && ln -s /lib/libc.musl-x86_64.so.1 /lib64/ld-linux-x86-64.so.2
apk add --no-cache --virtual .build-deps gcc build-base libtool sqlite-dev

# setup cloudflare ssl
echo "Setting up cloudflare SSL tools"
go get -u github.com/cloudflare/cfssl/cmd/cfssl
go get -u github.com/cloudflare/cfssl/cmd/cfssljson

# setup kubectl
echo "Setting up kubectl"
wget https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl
chmod +x ./kubectl
mv ./kubectl /usr/local/bin/kubectl

# setup tls for etcd
GEN_CLUSTER_SIZE=3
GEN_NAMESPACE="etcd-${PIPELINE_BUILD_ID}"
GEN_SERVER_SECRET_NAME="etcd-server-tls"
GEN_PEER_SECRET_NAME="etcd-peer-tls"
GEN_CLIENT_SECRET_NAME="etcd-client-tls"
GEN_STATEFULSET_NAME="etcd-vault"
GEN_CLUSTER_DOMAIN="cluster.local"

# create the namespace
echo "Creating namespace etcd-${PIPELINE_BUILD_ID}"
kubectl create namespace etcd-${PIPELINE_BUILD_ID}

# generate tls secrets for vault in GEN_NAMESPACE
echo "Generating etcd TLS certificates"
${PIPELINE_WORKSPACE}/charts/vault-etcd/tls-generator/generate-certs.sh