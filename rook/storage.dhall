let Prelude = ../Prelude.dhall

let kubernetes = ../kubernetes.dhall

let parameters = ./parameters.dhall

let PersistentBlockClaim =
      { Type =
          { name : Text
          , appName : Optional Text
          , accessModes : List Text
          , size : Text
          }
      , default = { appName = None Text, accessModes = [ "ReadWriteOnce" ] }
      }

let mkClaim
    : PersistentBlockClaim.Type -> kubernetes.PersistentVolumeClaim.Type
    = \(claim : PersistentBlockClaim.Type) ->
        kubernetes.PersistentVolumeClaim::{
        , metadata = kubernetes.ObjectMeta::{
          , name = Some claim.name
          , labels =
              Prelude.Optional.map
                Text
                (Prelude.Map.Type Text Text)
                (\(app : Text) -> toMap { app })
                claim.appName
          }
        , spec = Some kubernetes.PersistentVolumeClaimSpec::{
          , storageClassName = Some parameters.blockStorageName
          , accessModes = Some claim.accessModes
          , resources = Some kubernetes.ResourceRequirements::{
            , requests = Some (toMap { storage = claim.size })
            }
          }
        }

in  { PersistentBlockClaim, mkClaim }
