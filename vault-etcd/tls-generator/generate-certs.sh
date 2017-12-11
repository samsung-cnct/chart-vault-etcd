#!/bin/bash -
#title          :generate-certs.sh
#description    :runs a command on top of ssh
#author         :Samsung SDSRA
#====================================================================
set -o errexit
set -o nounset
set -o pipefail

my_dir=$(dirname "${BASH_SOURCE}")

POSITIONAL=()

function warn {
  echo -e "\033[1;33mWARNING: $1\033[0m"
}

function error {
  echo -e "\033[0;31mERROR: $1\033[0m"
}

function inf {
  echo -e "\033[0;32m$1\033[0m"
}


# borrowed from Hightower's K8s the hard way tut
# altered by Jim Conner
#
# *****************************************************

# CSR OPTIONS
COUNTRY="US"
CITY="Seattle"
ORGANIZATION="Samsung CNCT"
SUB_ORGANIZATION="Cyklops"
STATE="Washington"
BITS=2048
ALGO="rsa"

# DEPLOYMENT VARS (INIT VARS)
GEN_PEER_CERTS=""
GEN_HOSTS_SERVER="127.0.0.1"
GEN_HOSTS_CLIENT="127.0.0.1"

# DEPLOYMENT VARS (expect environment variables)
if [ -z ${GEN_CLUSTER_SIZE+x} ]; then
    GEN_CLUSTER_SIZE=3
fi

# namespace to deploy server and peer secrets
if [ -z ${GEN_NAMESPACE+x} ]; then
    GEN_NAMESPACE=""
fi

# array of namespaces to deploy client secrets
if [ -z ${GEN_CLIENT_NAMESPACES+x} ]; then
    GEN_CLIENT_NAMESPACES=( ${GEN_NAMESPACE} )
fi

# server secrets name
if [ -z ${GEN_SERVER_SECRET_NAME+x} ]; then
    GEN_SERVER_SECRET_NAME="etcd-server-tls"
fi

# peer secrets name
if [ -z ${GEN_PEER_SECRET_NAME+x} ]; then
    GEN_PEER_SECRET_NAME="etcd-peer-tls"
fi

# client secrets name
if [ -z ${GEN_CLIENT_SECRET_NAME+x} ]; then
    GEN_CLIENT_SECRET_NAME="etcd-client-tls"
fi

# statefulset name
if [ -z ${GEN_STATEFULSET_NAME+x} ]; then
    GEN_STATEFULSET_NAME="etcd-vault-etcd"
fi

function checkPREREQS() {
    PRE_REQS="cfssljson cfssl"

    for pr in $PRE_REQS
    do
      if ! which $pr >/dev/null 2>&1
      then
        echo >&2 "prerequisite application called '$pr' is not found on this system"
        return=1
      fi
    done

    return 0
}


EXIT_CODE=$(checkPREREQS)

[[ $EXIT_CODE > 0 ]] && exit $EXIT_CODE

DIR_PATH="${my_dir}/../etcd-certs"

# make sure the DIR_PATH exists.
if [ ! -d "$DIR_PATH" ]; then
    mkdir -p $DIR_PATH
fi

cd $DIR_PATH

if [[ ! -e ca-key.pem ]]; then
## generate the CA config
cat <<EOF > ca-config.json
{
    "signing": {
        "default": {
            "expiry": "43800h"
        },
        "profiles": {
            "server": {
                "expiry": "43800h",
                "usages": [
                    "signing",
                    "key encipherment",
                    "server auth",
                    "client auth"
                ]
            },
            "client": {
                "expiry": "43800h",
                "usages": [
                    "signing",
                    "key encipherment",
                    "server auth",
                    "client auth"
                ]
            },
            "peer": {
                "expiry": "43800h",
                "usages": [
                    "signing",
                    "key encipherment",
                    "server auth",
                    "client auth"
                ]
            }
        }
    }
}
EOF

# CA CSR
cat <<EOF > ca-csr.json
{
    "CN": "etcd CA",
    "key": {
        "algo": "$ALGO",
        "size": $BITS
    },
    "names": [
        {
            "C": "${COUNTRY}",
            "L": "${CITY}",
            "O": "${ORGANIZATION}",
            "OU": "${SUB_ORGANIZATION}",
            "ST": "${STATE}"
        }
    ]
}
EOF
fi

# Server CSR
cat <<EOF > server.json
{
    "CN": "etcd-server",
    "hosts": [""],
    "key": {
        "algo": "$ALGO",
        "size": $BITS
    },
    "names": [
        {
            "C": "${COUNTRY}",
            "L": "${CITY}",
            "O": "${ORGANIZATION}",
            "OU": "${SUB_ORGANIZATION}",
            "ST": "${STATE}"
        }
    ]
}
EOF

# Client CSR
cat <<EOF > client.json
{
    "CN": "etcd-client",
    "hosts": [""],
    "key": {
        "algo": "$ALGO",
        "size": $BITS
    },
    "names": [
        {
            "C": "${COUNTRY}",
            "L": "${CITY}",
            "O": "${ORGANIZATION}",
            "OU": "${SUB_ORGANIZATION}",
            "ST": "${STATE}"
        }
    ]
}
EOF

# Peer CSR
for ((i = 0; i < GEN_CLUSTER_SIZE; i++)); do
    GEN_HOSTS_SERVER="${GEN_HOSTS_SERVER},${GEN_STATEFULSET_NAME}-${i},${GEN_STATEFULSET_NAME}-${i}.${GEN_STATEFULSET_NAME}"
    GEN_HOSTS_CLIENT="${GEN_HOSTS_CLIENT},${GEN_STATEFULSET_NAME}-${i},${GEN_STATEFULSET_NAME}-${i}.${GEN_STATEFULSET_NAME}"

cat <<EOF > ${GEN_STATEFULSET_NAME}-${i}.json
{
    "CN": "${GEN_STATEFULSET_NAME}-${i}",
    "hosts": [""],
    "key": {
        "algo": "$ALGO",
        "size": $BITS
    },
    "names": [
        {
            "C": "${COUNTRY}",
            "L": "${CITY}",
            "O": "${ORGANIZATION}",
            "OU": "${SUB_ORGANIZATION}",
            "ST": "${STATE}"
        }
    ]
}
EOF
done

## CA certs
if [[ ! -e ca-key.pem ]]; then
    inf "generating CA certs..."
    inf 'cfssl gencert -initca ca-csr.json | cfssljson -bare ca'
    cfssl gencert \
        -initca ca-csr.json | cfssljson -bare ca
else
    warn "skipping ca creation, already found."
fi

# server certs
inf "generating server certs..."
inf "cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=client server.json | cfssljson -bare server"
cfssl gencert \
    -ca=ca.pem \
    -ca-key=ca-key.pem \
    -config=ca-config.json \
    -hostname=${GEN_HOSTS_SERVER} \
    -profile=client server.json | cfssljson -bare server

# peer certs
for ((i = 0; i < GEN_CLUSTER_SIZE; i++)); do
    inf "generating peer cert: ${GEN_STATEFULSET_NAME}-${i} ..."
    inf "cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=client ${GEN_STATEFULSET_NAME}-${i}.json | cfssljson -bare ${GEN_STATEFULSET_NAME}-${i}"
    cfssl gencert \
        -ca=ca.pem \
        -ca-key=ca-key.pem \
        -config=ca-config.json \
        -hostname="${GEN_STATEFULSET_NAME}-${i}","${GEN_STATEFULSET_NAME}-${i}.${GEN_STATEFULSET_NAME}","127.0.0.1" \
        -profile=client ${GEN_STATEFULSET_NAME}-${i}.json | cfssljson -bare ${GEN_STATEFULSET_NAME}-${i}
done

# client certs
inf "generating client certs..."
inf "cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=client client.json | cfssljson -bare client"
cfssl gencert \
    -ca=ca.pem \
    -ca-key=ca-key.pem \
    -config=ca-config.json \
    -hostname=${GEN_HOSTS_CLIENT} \
    -profile=client client.json | cfssljson -bare client


# clean out old secrets
kubectl -n ${GEN_NAMESPACE} delete secret ${GEN_PEER_SECRET_NAME} || true
kubectl -n ${GEN_NAMESPACE} delete secret ${GEN_SERVER_SECRET_NAME} || true
kubectl -n ${GEN_NAMESPACE} delete secret ${GEN_CLIENT_SECRET_NAME} || true

# add new secrets
for ((i = 0; i < GEN_CLUSTER_SIZE; i++)); do
    GEN_PEER_CERTS="${GEN_PEER_CERTS} --from-file=${GEN_STATEFULSET_NAME}-${i}.pem --from-file=${GEN_STATEFULSET_NAME}-${i}-key.pem"
done

inf "kubectl -n ${GEN_NAMESPACE} create secret generic ${GEN_PEER_SECRET_NAME} \
    --from-file=ca.pem \
    ${GEN_PEER_CERTS}"
warn "if namespaces does not exist, secret creation will be skipped"

kubectl -n ${GEN_NAMESPACE} create secret generic ${GEN_PEER_SECRET_NAME} \
    --from-file=ca.pem \
    ${GEN_PEER_CERTS}  || true

inf "kubectl -n ${GEN_NAMESPACE} create secret generic ${GEN_SERVER_SECRET_NAME} \
    --from-file=ca.pem --from-file=server.pem --from-file=server-key.pem"
warn "if namespaces does not exist, secret creation will be skipped"

kubectl -n ${GEN_NAMESPACE} create secret generic ${GEN_SERVER_SECRET_NAME} \
    --from-file=ca.pem \
    --from-file=server.pem \
    --from-file=server-key.pem || true

for ns in "${GEN_CLIENT_NAMESPACES[@]}"; do
inf "kubectl -n ${ns} create secret generic ${GEN_CLIENT_SECRET_NAME} \
    --from-file=ca.pem --from-file=client.pem --from-file=client-key.pem"
warn "if namespaces does not exist, secret creation will be skipped"

kubectl -n ${ns} create secret generic ${GEN_CLIENT_SECRET_NAME} \
    --from-file=ca.pem \
    --from-file=client.pem \
    --from-file=client-key.pem || true
done