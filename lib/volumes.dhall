let kubernetes = ../kubernetes.dhall

let storage = ./storage.dhall

let BlockStorageSource =
      { Type = { block : storage.Block.Type }, default = {=} }

let SecretSource = { Type = { secret : kubernetes.Secret.Type }, default = {=} }

let TZInfoSource =
      { Type = { timezone : Text }, default.timezone = "America/New_York" }

let VolumeSource =
      < BlockStorage : BlockStorageSource.Type
      | Secret : SecretSource.Type
      | TZInfo : TZInfoSource.Type
      >

let Volume =
      { Type =
          { name : Text
          , mountPath : Text
          , subPath : Optional Text
          , readOnly : Optional Bool
          , source : VolumeSource
          }
      , default = { subPath = None Text, readOnly = None Bool }
      }

let mkVolumeSource
    : Volume.Type -> kubernetes.Volume.Type
    = \(volume : Volume.Type) ->
        merge
          { BlockStorage =
              \(bsVolume : BlockStorageSource.Type) ->
                  kubernetes.Volume::{
                  , name = volume.name
                  , persistentVolumeClaim = Some kubernetes.PersistentVolumeClaimVolumeSource::{
                    , claimName = bsVolume.block.name
                    }
                  }
                : kubernetes.Volume.Type
          , Secret =
              \(sVolume : SecretSource.Type) ->
                  kubernetes.Volume::{
                  , name = volume.name
                  , secret = Some kubernetes.SecretVolumeSource::{
                    , secretName = sVolume.secret.metadata.name
                    }
                  }
                : kubernetes.Volume.Type
          , TZInfo =
              \(tzVolume : TZInfoSource.Type) ->
                  kubernetes.Volume::{
                  , name = volume.name
                  , hostPath = Some kubernetes.HostPathVolumeSource::{
                    , path = "/usr/share/zoneinfo/${tzVolume.timezone}"
                    }
                  }
                : kubernetes.Volume.Type
          }
          volume.source

let mkVolumeMount
    : Volume.Type -> kubernetes.VolumeMount.Type
    = \(volume : Volume.Type) ->
        kubernetes.VolumeMount::{
        , name = volume.name
        , mountPath = volume.mountPath
        , subPath = volume.subPath
        , readOnly = volume.readOnly
        }

in  { Volume
    , mkVolumeMount
    , VolumeSource
    , BlockStorageSource
    , SecretSource
    , TZInfoSource
    , mkVolumeSource
    }
