let Prelude = ../Prelude.dhall

let kubernetes = ../kubernetes.dhall

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

let PersistentBlockClaim =
      { Type =
          { name : Text
          , appName : Optional Text
          , accessModes : List Text
          , size : Text
          }
      , default = { appName = None Text, accessModes = [ "ReadWriteOnce" ] }
      }

let mkBlockStorageClaim
    : CephBlockPool.Type ->
      PersistentBlockClaim.Type ->
        kubernetes.PersistentVolumeClaim.Type
    = \(pool : CephBlockPool.Type) ->
      \(claim : PersistentBlockClaim.Type) ->
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

in  { CephBlockPool, PersistentBlockClaim, mkBlockStorageClaim }
