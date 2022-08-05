let Prelude = ../Prelude.dhall

let kubernetes = ../kubernetes.dhall

let rook = ../rook.dhall

let typesUnion = < Kubernetes : kubernetes.Resource | Rook : rook.Resource >

let parameters = ./parameters.dhall

let pool =
      rook.CephBlockPool::{
      , metadata = kubernetes.ObjectMeta::{
        , name = Some "replicapool"
        , namespace = Some parameters.namespace
        }
      , spec = rook.NamedBlockPoolSpec::{
        , failureDomain = Some parameters.blockPoolFailureDomain
        , replicated = Some rook.ReplicatedSpec::{
          , requireSafeReplicaSize = Some
              (Prelude.Natural.greaterThan parameters.blockPoolSize 1)
          , size = parameters.blockPoolSize
          }
        }
      }

let storage =
      kubernetes.StorageClass::{
      , metadata = kubernetes.ObjectMeta::{
        , name = Some parameters.blockStorageName
        }
      , provisioner = "${parameters.namespace}.rbd.csi.ceph.com"
      , parameters = Some
          ( toMap
              { clusterID = parameters.namespace
              , `csi.storage.k8s.io/controller-expand-secret-name` =
                  "rook-csi-rbd-provisioner"
              , `csi.storage.k8s.io/controller-expand-secret-namespace` =
                  "rook-ceph"
              , `csi.storage.k8s.io/fstype` = "ext4"
              , `csi.storage.k8s.io/node-stage-secret-name` =
                  "rook-csi-rbd-node"
              , `csi.storage.k8s.io/node-stage-secret-namespace` =
                  parameters.namespace
              , `csi.storage.k8s.io/provisioner-secret-name` =
                  "rook-csi-rbd-provisioner"
              , `csi.storage.k8s.io/provisioner-secret-namespace` =
                  parameters.namespace
              , imageFeatures = "layering"
              , imageFormat = "2"
              , pool = "replicapool"
              }
          )
      , allowVolumeExpansion = Some True
      , reclaimPolicy = Some "Delete"
      }

in  [ typesUnion.Rook (rook.Resource.CephBlockPool pool)
    , typesUnion.Kubernetes (kubernetes.Resource.StorageClass storage)
    ]
