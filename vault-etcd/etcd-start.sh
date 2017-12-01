#!/usr/bin/env sh

# store member id into PVC for later member replacement
collect_member() {
    while ! etcdctl member list &>/dev/null; do sleep 1; done
    etcdctl member list | grep ${HTTP_SCHEME}://${HOSTNAME}.${STATEFULSET_NAME}:${PEER_PORT} | cut -d':' -f1 | cut -d'[' -f1 > $DATA_DIR/member_id
    exit 0
}

eps() {
    EPS=""
    for i in $(seq 0 $((${INITIAL_CLUSTER_SIZE} - 1))); do
        EPS="${EPS}${EPS:+,}${HTTP_SCHEME}://${STATEFULSET_NAME}-${i}.${STATEFULSET_NAME}:${CLIENT_PORT}"
    done
    echo ${EPS}
}

member_hash() {
    etcdctl member list | grep ${HTTP_SCHEME}://${HOSTNAME}.${STATEFULSET_NAME}:${PEER_PORT} | cut -d':' -f1 | cut -d'[' -f1
}


HOSTNAME=$(hostname)
MY_IP=$(hostname -i)

# TLS OPTIONS
HTTP_SCHEME=http
FLAGS_TLS_OPTIONS=""
if [ -n "${TLS_ENABLED}+x" ] && [ "${TLS_ENABLED}" = true ]; then
    echo "using https, loading tls flags"
    HTTP_SCHEME=https
    FLAGS_TLS_OPTIONS="""
        --client-cert-auth \
        --trusted-ca-file=/etcd/certs/server/ca.pem \
        --cert-file=/etcd/certs/server/server.pem \
        --key-file=/etcd/certs/server/server-key.pem \
        --peer-client-cert-auth \
        --peer-trusted-ca-file=/etcd/certs/peer/ca.pem \
        --peer-cert-file=/etcd/certs/peer/${HOSTNAME}.pem \
        --peer-key-file=/etcd/certs/peer/${HOSTNAME}-key.pem
    """
fi


# re-joining after failure?
if [ -e ${DATA_DIR}/etcd ]; then
    echo "Re-joining etcd member"
    member_id=$(cat $DATA_DIR/member_id)

    # re-join member
    ETCDCTL_ENDPOINT=$(eps) etcdctl member update ${member_id} ${HTTP_SCHEME}://${HOSTNAME}.${STATEFULSET_NAME}:${PEER_PORT}
    exec etcd --name ${HOSTNAME} \
        --listen-peer-urls ${HTTP_SCHEME}://${MY_IP}:${PEER_PORT},${HTTP_SCHEME}://127.0.0.1:${PEER_PORT} \
        --listen-client-urls ${HTTP_SCHEME}://${MY_IP}:${CLIENT_PORT},${HTTP_SCHEME}://127.0.0.1:${CLIENT_PORT} \
        --advertise-client-urls ${HTTP_SCHEME}://${HOSTNAME}.${STATEFULSET_NAME}:${CLIENT_PORT} \
        --data-dir ${DATA_DIR}/etcd ${FLAGS_TLS_OPTIONS}
fi

# etcd-SET_ID
SET_ID=${HOSTNAME:5:${#HOSTNAME}}

# adding a new member to existing cluster (assuming all initial pods are available)
if [ "${SET_ID}" -ge ${INITIAL_CLUSTER_SIZE} ]; then
    export ETCDCTL_ENDPOINT=$(eps)

    # member already added?
    MEMBER_HASH=$(member_hash)
    if [ -n "${MEMBER_HASH}" ]; then
        # the member hash exists but for some reason etcd failed
        # as the datadir has not be created, we can remove the member
        # and retrieve new hash
        etcdctl member remove ${MEMBER_HASH}
    fi

    echo "Adding new member"
    etcdctl member add ${HOSTNAME} ${HTTP_SCHEME}://${HOSTNAME}.${STATEFULSET_NAME}:${PEER_PORT} | grep "^ETCD_" > ${DATA_DIR}/new_member_envs

    if [ $? -ne 0 ]; then
        echo "Exiting"
        rm -f ${DATA_DIR}/new_member_envs
        exit 1
    fi

    cat ${DATA_DIR}/new_member_envs
    source ${DATA_DIR}/new_member_envs

    collect_member &

    exec etcd --name ${HOSTNAME} \
        --listen-peer-urls ${HTTP_SCHEME}://${MY_IP}:${PEER_PORT},${HTTP_SCHEME}://127.0.0.1:${PEER_PORT} \
        --listen-client-urls ${HTTP_SCHEME}://${MY_IP}:${CLIENT_PORT},${HTTP_SCHEME}://127.0.0.1:${CLIENT_PORT} \
        --advertise-client-urls ${HTTP_SCHEME}://${HOSTNAME}.${STATEFULSET_NAME}:${CLIENT_PORT} \
        --initial-advertise-peer-urls ${HTTP_SCHEME}://${HOSTNAME}.${STATEFULSET_NAME}:${PEER_PORT} \
        --initial-cluster ${ETCD_INITIAL_CLUSTER} \
        --initial-cluster-state ${ETCD_INITIAL_CLUSTER_STATE} \
        --data-dir ${DATA_DIR}/etcd ${FLAGS_TLS_OPTIONS}
fi

for i in $(seq 0 $((${INITIAL_CLUSTER_SIZE} - 1))); do
    while true; do
        echo "Waiting for ${STATEFULSET_NAME}-${i}.${STATEFULSET_NAME} to come up"
        ping -W 1 -c 1 ${STATEFULSET_NAME}-${i}.${STATEFULSET_NAME} > /dev/null && break
        sleep 1s
    done
done

PEERS=""
for i in $(seq 0 $((${INITIAL_CLUSTER_SIZE} - 1))); do
    PEERS="${PEERS}${PEERS:+,}${STATEFULSET_NAME}-${i}=${HTTP_SCHEME}://${STATEFULSET_NAME}-${i}.${STATEFULSET_NAME}:${PEER_PORT}"
done

collect_member &

cmd="""
exec etcd --name ${HOSTNAME} \
    --initial-advertise-peer-urls ${HTTP_SCHEME}://${HOSTNAME}.${STATEFULSET_NAME}:${PEER_PORT} \
    --listen-peer-urls ${HTTP_SCHEME}://${MY_IP}:${PEER_PORT},${HTTP_SCHEME}://127.0.0.1:${PEER_PORT} \
    --listen-client-urls ${HTTP_SCHEME}://${MY_IP}:${CLIENT_PORT},${HTTP_SCHEME}://127.0.0.1:${CLIENT_PORT} \
    --advertise-client-urls ${HTTP_SCHEME}://${HOSTNAME}.${STATEFULSET_NAME}:${CLIENT_PORT} \
    --initial-cluster-token etcd-cluster-1 \
    --initial-cluster ${PEERS} \
    --initial-cluster-state new \
    --data-dir ${DATA_DIR}/etcd ${FLAGS_TLS_OPTIONS}
"""

# join member
echo "$cmd"
$cmd
