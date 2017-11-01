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

| Parameter                                         | Description                                                          | Default                                        |
| ------------------------------------------------- | -------------------------------------------------------------------- | ---------------------------------------------- |
| component                                         | Name to use for the component                                        | "etcd"                                         |
| image.source                                      | Docker Image to use for etcd, should have etcd and etcdctl.          | "quay.io/coreos/etcd"                          |
| image.tag                                         | Version of the docker image to use.                                  | "v3.2.9"                                       |
| image.pullPolicy                                  | Pull policy for the docker image.                                    | "Always"                                       |
| service.name                                      | Name of the service                                                  | etcdvault                                      |
| service.peerPort                                  | Port to use for peer to peer communication, traditionally 2380       | 3380                                           |
| service.clientPort                                | Port used by a client , traditionally 2379                           | 3379                                           |
| service.replicas                                  | Number of etcd instances to use                                      | 5                                              |
| service.cpu                                       |                                                                      | "100m"                                         |
| service.memory                                    |                                                                      | "512Mi"                                        |
| service.dataDir                                   |                                                                      | "/ephemeral"                                   |
| service.terminationGracePeriodSeconds             | Amount of time given to the process to terminate before trying to forcefully terminate. We strongly suggest not to set this as 0.  | 30 |
| storage.storageClass                              | Persistent Volume Storage Class. Default is "default", if set to null, no storageClassName spec is set automatically selecting default for cloud provider (gp2 on AWS, standard on GKE)    | "default"      |
| storage.size                                      | The size of the volume to store etcd data on.                        | 1Gi                                            |
| storage.mount                                     | Name of the mount to use for etcd data.                              | "ephemeral"                                    |
| storage.accessModes                               | Array of accessmodes to set for the volume.                          | - ReadWriteOnce                                             |
