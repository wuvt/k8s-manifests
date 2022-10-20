let Prelude = ../Prelude.dhall

let kubernetes = ../kubernetes.dhall

let networking = ./networking.dhall

let storage = ./storage.dhall

let util = ./util.dhall

let SecretSource =
      { Type = { secret : kubernetes.Secret.Type, key : Text }, default = {=} }

let VariableSource = < Value : Text | Secret : SecretSource.Type >

let Variable =
      { Type = { name : Text, source : VariableSource }, default = {=} }

let mkVariable
    : Variable.Type -> kubernetes.EnvVar.Type
    = \(variable : Variable.Type) ->
        merge
          { Value =
              \(value : Text) ->
                kubernetes.EnvVar::{ name = variable.name, value = Some value }
          , Secret =
              \(secret : SecretSource.Type) ->
                kubernetes.EnvVar::{
                , name = variable.name
                , valueFrom = Some kubernetes.EnvVarSource::{
                  , secretKeyRef = Some kubernetes.SecretKeySelector::{
                    , name = secret.secret.metadata.name
                    , key = secret.key
                    }
                  }
                }
          }
          variable.source

let Container =
      { Type =
          { name : Optional Text
          , image : Text
          , command : List Text
          , args : List Text
          , env : List Variable.Type
          , volumes : List storage.Volume.Type
          , service : Optional networking.Service.Type
          , bucket : Optional storage.Bucket.Type
          }
      , default =
        { name = None Text
        , command = [] : List Text
        , args = [] : List Text
        , env = [] : List Variable.Type
        , volumes = [] : List storage.Volume.Type
        , service = None networking.Service.Type
        , bucket = None storage.Bucket.Type
        }
      }

let App =
      { Type =
          { name : Text
          , instance : Optional Text
          , replicas : Natural
          , nodeName : Optional Text
          , user : Optional Natural
          , containers : List Container.Type
          }
      , default =
        { instance = None Text
        , replicas = 1
        , nodeName = None Text
        , user = None Natural
        , containers = [] : List Container.Type
        }
      }

let mkLabels
    : App.Type -> Prelude.Map.Type Text Text
    = \(app : App.Type) ->
          toMap { `app.kubernetes.io/name` = app.name }
        # util.mapDefault
            Text
            (Prelude.Map.Type Text Text)
            ( \(instance : Text) ->
                toMap
                  { `app.kubernetes.io/instance` = "${app.name}-${instance}" }
            )
            ([] : Prelude.Map.Type Text Text)
            app.instance

let mkFullName
    : App.Type -> Text
    = \(app : App.Type) ->
        util.mapDefault
          Text
          Text
          (\(instance : Text) -> "${app.name}-${instance}")
          app.name
          app.instance

let mkContainer
    : Text -> Container.Type -> kubernetes.Container.Type
    = \(appName : Text) ->
      \(container : Container.Type) ->
        kubernetes.Container::{
        , image = Some container.image
        , name = Prelude.Optional.default Text appName container.name
        , volumeMounts =
            util.mapEmpty
              storage.Volume.Type
              kubernetes.VolumeMount.Type
              storage.mkVolumeMount
              container.volumes
        , livenessProbe =
            Prelude.Optional.concatMap
              networking.Service.Type
              kubernetes.Probe.Type
              networking.mkLivenessProbe
              container.service
        , command = util.listOptional Text container.command
        , args = util.listOptional Text container.args
        , ports =
            Prelude.Optional.map
              networking.Service.Type
              (List kubernetes.ContainerPort.Type)
              networking.mkContainerPorts
              container.service
        , env =
            util.listOptional
              kubernetes.EnvVar.Type
              ( Prelude.List.map
                  Variable.Type
                  kubernetes.EnvVar.Type
                  mkVariable
                  container.env
              )
        , envFrom =
            Prelude.Optional.map
              storage.Bucket.Type
              (List kubernetes.EnvFromSource.Type)
              ( \(bucket : storage.Bucket.Type) ->
                  [ kubernetes.EnvFromSource::{
                    , configMapRef = Some kubernetes.ConfigMapEnvSource::{
                      , name = Some "${appName}-${bucket.name}"
                      }
                    }
                  , kubernetes.EnvFromSource::{
                    , secretRef = Some kubernetes.SecretEnvSource::{
                      , name = Some "${appName}-${bucket.name}"
                      }
                    }
                  ]
              )
              container.bucket
        }

in  { App
    , mkLabels
    , mkFullName
    , Container
    , mkContainer
    , Variable
    , mkVariable
    , VariableSource
    , SecretSource
    }
