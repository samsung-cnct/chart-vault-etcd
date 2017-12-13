# Cyklops Chart: etcd for vault
This repo contains a chart specific to Cycklops implementation of etcd to be consumed by vault.  

## Installing

```
helm install vault-etcd --name etcd
```

## Deleting

```
helm delete --purge etcd
```

## Configuration

| Parameter                                           | Description                                                          | Default                                        |
| --------------------------------------------------- | -------------------------------------------------------------------- | ---------------------------------------------- |
| `rbac.create`                                       | Install rbac resources                                               | true                                           |
| `rbac.apiVersion`                                   | Define the version of rbac resources to use.                         | "v1beta1"                                      |
| `image.serviceAccountName`                          | Name of the service account resource when rbac is enabled            | "vault-etcd-sa"                          |
| `image.source`                                      | Docker Image to use for etcd, should have etcd and etcdctl.          | "quay.io/coreos/etcd"                          |
| `image.tag`                                         | Version of the docker image to use.                                  | "v3.2.9"                                       |
| `image.pullPolicy`                                  | Pull policy for the docker image.                                    | "Always"                                       |
| `service.name`                                      | Name of the service                                                  | etcdvault                                      |
| `service.peerPort`                                  | Port to use for peer to peer communication, traditionally 2380       | 3380                                           |
| `service.clientPort`                                | Port used by a client , traditionally 2379                           | 3379                                           |
| `service.replicas`                                  | Number of etcd instances to use                                      | 5                                              |
| `service.cpu`                                       |                                                                      | "100m"                                         |
| `service.memory`                                    |                                                                      | "512Mi"                                        |
| `service.dataDir`                                   |                                                                      | "/ephemeral"                                   |
| `service.terminationGracePeriodSeconds`             | Amount of time given to the process to terminate before trying to forcefully terminate. We strongly suggest not to set this as 0.  | 30 |
| `service.tls.enable`                                | Enable TLS on cluster, involves server and peer certs                | false                                          |
| `service.tls.serverSecret.name`                     | Name of secret containing server certs                               | etcd-server-tls                                |
| `service.tls.serverSecret.path`                     | Path of secret containing server certs                               | /etcd/certs/server                             |
| `service.tls.peerSecret.name`                       | Name of secret containing peer certs                                 | etcd-peer-tls                                  |
| `service.tls.peerSecret.path`                       | Path of secret containing peer certs                                 | /etcd/certs/peer                               |
| `service.tls.clientSecret.name`                     | Name of secret containing client certs (not consumed by etcd)        | etcd-client-tls                                |
| `service.tls.clientSecret.path`                     | Path of secret containing client certs (not consumed by etcd)        | /etcd/certs/client                             |
| `service.memory`                                    |                                                                      | "512Mi"                                        |
| `service.memory`                                    |                                                                      | "512Mi"                                        |
| `storage.storageClass`                              | Persistent Volume Storage Class. Default is "default", if set to null, no storageClassName spec is set automatically selecting default for cloud provider (gp2 on AWS, standard on GKE)    | "default"      |
| `storage.size`                                      | The size of the volume to store etcd data on.                        | 1Gi                                            |
| `storage.mount`                                     | Name of the mount to use for etcd data.                              | "ephemeral"                                    |
| `storage.accessModes`                               | Array of accessmodes to set for the volume.                          | - ReadWriteOnce                                |
| `nodeSelector.nodepool`                             | Select which node to place your etcd pod(s)                          | clusterNodes                                   |



## Enabling TLS 
It is recommended that before creating a cluster that is secured by tls that a test cluster is deployed containing
all the adjusted values that will be used (such as the cluster sizes). These choices will dictate what to assign 
certain variables when it comes to deploying a full tls enabled etcd cluster with properly created certs.

Cleanly remove your test cluster when you are ready, and follow the steps below to generate certs and then deploy your
cluster.

#### Generating Certs

You will first assign values to the variables corresponding to specifics of your deployment:

| Parameter                                           | Description                                                          | Default                                        |
| --------------------------------------------------- | -------------------------------------------------------------------- | ---------------------------------------------- |
| `GEN_CLUSTER_SIZE`                                  | Size of the etcd cluster                                             | 3                                              |
| `GEN_KUBERNETES_SECRET_SERVER`                      | Name of the secret containting server certs, must match values file  | "etcd-server-tls"                              |
| `GEN_KUBERNETES_SECRET_PEER`                        | Name of the secret containting peer certs, must match values file    | "etcd-peer-tls"                                |
| `GEN_KUBERNETES_SECRET_CLIENT`                      | Name of the secret containting client certs, must match values file  | "etcd-client-tls"                              |
| `GEN_STATEFULSET_NAME`                              | Name of the statefulset you are deploying                            | "etcd-vault-etcd"                              |
| `GEN_NAMESPACE`                                     | Namespaces of your deployment                                        | "gp2"                                          |
| `GEN_CLIENT_NAMESPACES`                             | Bash array of namespaces of clients that needs etcd certs.           | ("vault-staging")                              |
| `GEN_HOSTS_SERVER`                                  | Init hosts for the server certificate (probably wont need to change) | "127.0.0.1"                                    |
| `GEN_HOSTS_CLIENT`                                  | Init hosts for the client certificate (probably wont need to change) | "127.0.0.1"                                    |

You will then run the following command:

```
./tls-generator/generate-certs.sh
```

producing certs in a folder named `etcd-certs` that contains the `ca-key.pem` file which should be stored safely away, and additional `*-key.pem` files for server, client, and peer certs.
The script will remove any previously stored certs and will inject new ones to your cluster, assuming that kubectl is set up correctly and targets your kubernetes cluster. Once the script
has terminated, and you stored your `ca-key.pem` in a safe place, you can now deploy your etcd cluster with `service.tls.enable=true` option and the additional `tls` values. 

Verify that the cluster is healthy and your certs work by executing the following in any of the pods for the cluster that have come up:

```
etcdctl --endpoints "https://etcd-vault-etcd-0.etcd-vault-etcd:3379,https://etcd-vault-etcd-1.etcd-vault-etcd:3379,https://etcd-vault-e
tcd-2.etcd-vault-etcd:3379" --ca-file=/etcd/certs/server/ca.pem --cert-file=/etcd/certs/server/server.pem --key-file=/etcd/certs/server/ser
ver-key.pem cluster-health
```

whose response should be:

```
member 21881b5cae4be227 is healthy: got healthy result from https://etcd-vault-etcd-0.etcd-vault-etcd:3379
member 38cc4533e9389bcf is healthy: got healthy result from https://etcd-vault-etcd-2.etcd-vault-etcd:3379
member 3ea7877f5b314faa is healthy: got healthy result from https://etcd-vault-etcd-1.etcd-vault-etcd:3379
cluster is healthy
```
