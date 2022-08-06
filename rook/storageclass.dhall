let Prelude = ../Prelude.dhall

let kubernetes = ../kubernetes.dhall

let rook = ../rook.dhall

let blockStorage = (./blockStorage.dhall).pool

let pool =
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

let storage =
      kubernetes.StorageClass::{
      , metadata = kubernetes.ObjectMeta::{
        , name = Some blockStorage.storageName
        }
      , provisioner = "${blockStorage.namespace}.rbd.csi.ceph.com"
      , parameters = Some
          ( toMap
              { clusterID = blockStorage.namespace
              , `csi.storage.k8s.io/controller-expand-secret-name` =
                  "rook-csi-rbd-provisioner"
              , `csi.storage.k8s.io/controller-expand-secret-namespace` =
                  "rook-ceph"
              , `csi.storage.k8s.io/fstype` = "ext4"
              , `csi.storage.k8s.io/node-stage-secret-name` =
                  "rook-csi-rbd-node"
              , `csi.storage.k8s.io/node-stage-secret-namespace` =
                  blockStorage.namespace
              , `csi.storage.k8s.io/provisioner-secret-name` =
                  "rook-csi-rbd-provisioner"
              , `csi.storage.k8s.io/provisioner-secret-namespace` =
                  blockStorage.namespace
              , imageFeatures = "layering"
              , imageFormat = "2"
              , pool = "replicapool"
              }
          )
      , allowVolumeExpansion = Some True
      , reclaimPolicy = Some "Delete"
      }

let typesUnion = < Kubernetes : kubernetes.Resource | Rook : rook.Resource >

in  [ typesUnion.Rook (rook.Resource.CephBlockPool pool)
    , typesUnion.Kubernetes (kubernetes.Resource.StorageClass storage)
    ]
