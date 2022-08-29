let Prelude = ../Prelude.dhall

let kubernetes = ../kubernetes.dhall

let rook = ../rook.dhall

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
          , appName : Optional Text
          , accessModes : List Text
          , size : Text
          }
      , default = { appName = None Text, accessModes = [ "ReadWriteOnce" ] }
      }

let mkBlockStorageClaim
    : CephBlockPool.Type -> Block.Type -> kubernetes.PersistentVolumeClaim.Type
    = \(pool : CephBlockPool.Type) ->
      \(claim : Block.Type) ->
        kubernetes.PersistentVolumeClaim::{
        , metadata = kubernetes.ObjectMeta::{
          , name = Some claim.name
          , labels =
              Prelude.Optional.map
                Text
                (Prelude.Map.Type Text Text)
                (\(name : Text) -> toMap { `app.kubernetes.io/name` = name })
                claim.appName
          }
        , spec = Some kubernetes.PersistentVolumeClaimSpec::{
          , storageClassName = Some pool.storageName
          , accessModes = Some claim.accessModes
          , resources = Some kubernetes.ResourceRequirements::{
            , requests = Some (toMap { storage = claim.size })
            }
          }
        }

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
      { Type = { name : Text, appName : Optional Text }
      , default.appName = None Text
      }

let mkObjectBucketClaim
    : CephObjectStore.Type -> Bucket.Type -> rook.ObjectBucketClaim.Type
    = \(store : CephObjectStore.Type) ->
      \(claim : Bucket.Type) ->
        rook.ObjectBucketClaim::{
        , metadata = kubernetes.ObjectMeta::{
          , name = Some claim.name
          , labels =
              Prelude.Optional.map
                Text
                (Prelude.Map.Type Text Text)
                (\(name : Text) -> toMap { `app.kubernetes.io/name` = name })
                claim.appName
          }
        , spec = Some rook.ObjectBucketClaimSpec::{
          , storageClassName = store.storageName
          , generateBucketName = Some claim.name
          }
        }

in  { CephBlockPool
    , Block
    , mkBlockStorageClaim
    , CephObjectStore
    , Bucket
    , mkObjectBucketClaim
    }
