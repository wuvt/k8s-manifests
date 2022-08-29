let Prelude = ../Prelude.dhall

let kubernetes = ../kubernetes.dhall

let rook = ../rook.dhall

let typesUnion = ./typesUnion.dhall

let CephBlockPool =
      { Type =
          { name : Text
          , storageName : Text
          , namespace : Text
          , failureDomain : Text
          , replicas : Natural
          }
      , default = {=}
      }

let Block =
      { Type =
          { name : Text
          , store : CephBlockPool.Type
          , appName : Optional Text
          , accessModes : List Text
          , size : Text
          }
      , default = { appName = None Text, accessModes = [ "ReadWriteOnce" ] }
      }

let mkBlockStorageClaim
    : Block.Type -> typesUnion
    = \(block : Block.Type) ->
        let claim =
              kubernetes.PersistentVolumeClaim::{
              , metadata = kubernetes.ObjectMeta::{
                , name = Some block.name
                , labels =
                    Prelude.Optional.map
                      Text
                      (Prelude.Map.Type Text Text)
                      ( \(name : Text) ->
                          toMap { `app.kubernetes.io/name` = name }
                      )
                      block.appName
                }
              , spec = Some kubernetes.PersistentVolumeClaimSpec::{
                , storageClassName = Some block.store.storageName
                , accessModes = Some block.accessModes
                , resources = Some kubernetes.ResourceRequirements::{
                  , requests = Some (toMap { storage = block.size })
                  }
                }
              }

        in  typesUnion.Kubernetes
              (kubernetes.Resource.PersistentVolumeClaim claim)

let CephObjectStore =
      { Type =
          { name : Text
          , storageName : Text
          , namespace : Text
          , failureDomain : Text
          , replicas : Natural
          , gatewayInstances : Natural
          , healthCheckInterval : Text
          }
      , default = {=}
      }

let Bucket =
      { Type =
          { name : Text, store : CephObjectStore.Type, appName : Optional Text }
      , default.appName = None Text
      }

let mkObjectBucketClaim
    : Bucket.Type -> typesUnion
    = \(bucket : Bucket.Type) ->
        let claim =
              rook.ObjectBucketClaim::{
              , metadata = kubernetes.ObjectMeta::{
                , name = Some bucket.name
                , labels =
                    Prelude.Optional.map
                      Text
                      (Prelude.Map.Type Text Text)
                      ( \(name : Text) ->
                          toMap { `app.kubernetes.io/name` = name }
                      )
                      bucket.appName
                }
              , spec = Some rook.ObjectBucketClaimSpec::{
                , storageClassName = bucket.store.storageName
                , generateBucketName = Some bucket.name
                }
              }

        in  typesUnion.Rook (rook.Resource.ObjectBucketClaim claim)

in  { CephBlockPool
    , Block
    , mkBlockStorageClaim
    , CephObjectStore
    , Bucket
    , mkObjectBucketClaim
    }
