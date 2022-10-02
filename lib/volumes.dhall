let kubernetes = ../kubernetes.dhall

let config = ./config.dhall

let storage = ./storage.dhall

let BlockStorageSource =
      { Type = { block : storage.Block.Type }, default = {=} }

let ConfigMapSource =
      { Type = { configMap : config.ConfigMap.Type }, default = {=} }

let HostSource = { Type = { path : Text }, default = {=} }

let SecretSource = { Type = { secret : kubernetes.Secret.Type }, default = {=} }

let TZInfoSource =
      { Type = { timezone : Text }, default.timezone = "America/New_York" }

let VolumeSource =
      < BlockStorage : BlockStorageSource.Type
      | ConfigMap : ConfigMapSource.Type
      | Host : HostSource.Type
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
          , ConfigMap =
              \(cmVolume : ConfigMapSource.Type) ->
                kubernetes.Volume::{
                , name = volume.name
                , configMap = Some kubernetes.ConfigMapVolumeSource::{
                  , name = Some cmVolume.configMap.name
                  }
                }
          , Host =
              \(hVolume : HostSource.Type) ->
                kubernetes.Volume::{
                , name = volume.name
                , hostPath = Some kubernetes.HostPathVolumeSource::{
                  , path = hVolume.path
                  }
                }
          , Secret =
              \(sVolume : SecretSource.Type) ->
                kubernetes.Volume::{
                , name = volume.name
                , secret = Some kubernetes.SecretVolumeSource::{
                  , secretName = sVolume.secret.metadata.name
                  }
                }
          , TZInfo =
              \(tzVolume : TZInfoSource.Type) ->
                kubernetes.Volume::{
                , name = volume.name
                , hostPath = Some kubernetes.HostPathVolumeSource::{
                  , path = "/usr/share/zoneinfo/${tzVolume.timezone}"
                  }
                }
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
    , ConfigMapSource
    , HostSource
    , SecretSource
    , TZInfoSource
    , mkVolumeSource
    }
