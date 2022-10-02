let Prelude = ../Prelude.dhall

let kubernetes = ../kubernetes.dhall

let rook = ../rook.dhall

let blockStorage = ./blockStorage.dhall

let objectStorage = ./objectStorage.dhall

let typesUnion = (../lib.dhall).typesUnion

let blockPool =
      rook.CephBlockPool::{
      , metadata = kubernetes.ObjectMeta::{
        , name = Some blockStorage.name
        , namespace = Some blockStorage.namespace
        }
      , spec = rook.NamedBlockPoolSpec::{
        , failureDomain = Some blockStorage.failureDomain
        , replicated = Some rook.ReplicatedSpec::{
          , requireSafeReplicaSize = Some
              (Prelude.Natural.greaterThan blockStorage.replicas 1)
          , size = blockStorage.replicas
          }
        }
      }

let blockClass =
      kubernetes.StorageClass::{
      , metadata = kubernetes.ObjectMeta::{
        , name = Some blockStorage.storageName
        }
      , provisioner = "${blockStorage.namespace}.rbd.csi.ceph.com"
      , parameters = Some
          ( toMap
              { clusterID = blockStorage.namespace
              , pool = blockStorage.name
              , imageFormat = "2"
              , imageFeatures = "layering"
              , `csi.storage.k8s.io/controller-expand-secret-name` =
                  "rook-csi-rbd-provisioner"
              , `csi.storage.k8s.io/controller-expand-secret-namespace` =
                  blockStorage.namespace
              , `csi.storage.k8s.io/node-stage-secret-name` =
                  "rook-csi-rbd-node"
              , `csi.storage.k8s.io/node-stage-secret-namespace` =
                  blockStorage.namespace
              , `csi.storage.k8s.io/provisioner-secret-name` =
                  "rook-csi-rbd-provisioner"
              , `csi.storage.k8s.io/provisioner-secret-namespace` =
                  blockStorage.namespace
              , `csi.storage.k8s.io/fstype` = "ext4"
              }
          )
      , allowVolumeExpansion = Some True
      , reclaimPolicy = Some "Delete"
      }

let objectStore =
      rook.CephObjectStore::{
      , metadata = kubernetes.ObjectMeta::{
        , name = Some objectStorage.name
        , namespace = Some objectStorage.namespace
        }
      , spec = rook.ObjectStoreSpec::{
        , metadataPool = Some rook.PoolSpec::{
          , failureDomain = Some objectStorage.failureDomain
          , replicated = Some rook.ReplicatedSpec::{
            , requireSafeReplicaSize = Some
                (Prelude.Natural.greaterThan objectStorage.replicas 1)
            , size = objectStorage.replicas
            }
          }
        , dataPool = Some rook.PoolSpec::{
          , failureDomain = Some objectStorage.failureDomain
          , replicated = Some rook.ReplicatedSpec::{
            , requireSafeReplicaSize = Some
                (Prelude.Natural.greaterThan objectStorage.replicas 1)
            , size = objectStorage.replicas
            }
          }
        , gateway = Some rook.GatewaySpec::{
          , instances = Some objectStorage.gatewayInstances
          }
        , healthCheck = Some rook.BucketHealthCheckSpec::{
          , bucket = Some rook.HealthCheckSpec::{
            , disabled = Some False
            , interval = Some objectStorage.healthCheckInterval
            }
          }
        }
      }

let objectClass =
      kubernetes.StorageClass::{
      , metadata = kubernetes.ObjectMeta::{
        , name = Some objectStorage.storageName
        }
      , provisioner = "${objectStorage.namespace}.rbd.csi.ceph.com"
      , parameters = Some
          ( toMap
              { objectStoreName = objectStorage.name
              , objectStoreNamespace = objectStorage.namespace
              }
          )
      , reclaimPolicy = Some "Delete"
      }

in  [ typesUnion.Rook (rook.Resource.CephBlockPool blockPool)
    , typesUnion.Kubernetes (kubernetes.Resource.StorageClass blockClass)
    , typesUnion.Rook (rook.Resource.CephObjectStore objectStore)
    , typesUnion.Kubernetes (kubernetes.Resource.StorageClass objectClass)
    ]
