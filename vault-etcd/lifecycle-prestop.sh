#!/usr/bin/env sh

# TLS OPTIONS
HTTP_SCHEME=http
if [- n "${TLS_ENABLED}+x" ] && [ "${TLS_ENABLED}" = true]; then
    HTTP_SCHEME=https
fi



EPS=""
for i in $(seq 0 $((${INITIAL_CLUSTER_SIZE} - 1))); do
  EPS="${EPS}${EPS:+,}${HTTP_SCHEME}://${STATEFULSET_NAME}-${i}.${STATEFULSET_NAME}:${CLIENT_PORT}"
done

HOSTNAME=$(hostname)

member_hash() {
  etcdctl member list | grep ${HTTP_SCHEME}://${HOSTNAME}.${STATEFULSET_NAME}:${PEER_PORT} | cut -d':' -f1 | cut -d'[' -f1
}

echo "Removing ${HOSTNAME} from etcd cluster"

ETCDCTL_ENDPOINT=${EPS} etcdctl member remove $(member_hash)
if [ $? -eq 0 ]; then
  # Remove everything otherwise the cluster will no longer scale-up
  rm -rf $DATA_DIR/*
fi