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

# DEPLOYMENT VARS
CLUSTER_SIZE=3
PEER_CERTS=""
KUBERNETES_SECRET_SERVER="etcd-server-tls"
KUBERNETES_SECRET_PEER="etcd-peer-tls"
KUBERNETES_SECRET_CLIENT="etcd-client-tls"
STATEFULSET_NAME="etcd-vault-etcd"
HOSTNAME_PREFIX="etcd-vault-etcd"
NAMESPACE="vault2"
HOSTS_SERVER="127.0.0.1"
HOSTS_CLIENT="127.0.0.1"


function checkPREREQS() {
    PRE_REQS="cfssljson cfssl base64"

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
[[ ! -d "$DIR_PATH" ]] && {
    mkdir -p $DIR_PATH || \
      echo >&2 "unable to make output directory: '$DIR_PATH'" && exit 1
  }

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
for ((i = 0; i < CLUSTER_SIZE; i++)); do
    HOSTS_SERVER="${HOSTS_SERVER},${HOSTNAME_PREFIX}-${i},${HOSTNAME_PREFIX}-${i}.${STATEFULSET_NAME}"
    HOSTS_CLIENT="${HOSTS_CLIENT},${HOSTNAME_PREFIX}-${i},${HOSTNAME_PREFIX}-${i}.${STATEFULSET_NAME}"

cat <<EOF > ${HOSTNAME_PREFIX}-${i}.json
{
    "CN": "${HOSTNAME_PREFIX}-${i}",
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
    -hostname=${HOSTS_SERVER} \
    -profile=client server.json | cfssljson -bare server

# peer certs
for ((i = 0; i < CLUSTER_SIZE; i++)); do
    inf "generating peer cert: ${HOSTNAME_PREFIX}-${i} ..."
    inf "cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=client ${HOSTNAME_PREFIX}-${i}.json | cfssljson -bare ${HOSTNAME_PREFIX}-${i}"
    cfssl gencert \
        -ca=ca.pem \
        -ca-key=ca-key.pem \
        -config=ca-config.json \
        -hostname="${HOSTNAME_PREFIX}-${i}","${HOSTNAME_PREFIX}-${i}.${STATEFULSET_NAME}","127.0.0.1" \
        -profile=client ${HOSTNAME_PREFIX}-${i}.json | cfssljson -bare ${HOSTNAME_PREFIX}-${i}
done

# client certs
inf "generating client certs..."
inf "cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=client client.json | cfssljson -bare client"
cfssl gencert \
    -ca=ca.pem \
    -ca-key=ca-key.pem \
    -config=ca-config.json \
    -hostname=${HOSTS_CLIENT} \
    -profile=client client.json | cfssljson -bare client


# clean out old secrets
kubectl -n ${NAMESPACE} delete secret ${KUBERNETES_SECRET_PEER} || true
kubectl -n ${NAMESPACE} delete secret ${KUBERNETES_SECRET_SERVER} || true
kubectl -n ${NAMESPACE} delete secret ${KUBERNETES_SECRET_CLIENT} || true

# add new secrets
for ((i = 0; i < CLUSTER_SIZE; i++)); do
    PEER_CERTS="${PEER_CERTS} --from-file=${HOSTNAME_PREFIX}-${i}.pem --from-file=${HOSTNAME_PREFIX}-${i}-key.pem"
done

kubectl -n ${NAMESPACE} create secret generic ${KUBERNETES_SECRET_PEER} \
    --from-file=ca.pem \
    ${PEER_CERTS}

kubectl -n ${NAMESPACE} create secret generic ${KUBERNETES_SECRET_SERVER} \
    --from-file=ca.pem \
    --from-file=server.pem \
    --from-file=server-key.pem

kubectl -n ${NAMESPACE} create secret generic ${KUBERNETES_SECRET_CLIENT} \
    --from-file=ca.pem \
    --from-file=client.pem \
    --from-file=client-key.pem
