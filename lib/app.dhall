let Prelude = ../Prelude.dhall

let kubernetes = ../kubernetes.dhall

let env = ./env.dhall

let services = ./services.dhall

let storage = ./storage.dhall

let typesUnion = ./typesUnion.dhall

let util = ./util.dhall

let volumes = ./volumes.dhall

let Container =
      { Type =
          { name : Optional Text
          , image : Text
          , command : List Text
          , args : List Text
          , env : List env.Variable.Type
          , volumes : List volumes.Volume.Type
          , service : Optional services.Service.Type
          , bucket : Optional storage.Bucket.Type
          }
      , default =
        { name = None Text
        , command = [] : List Text
        , args = [] : List Text
        , env = [] : List env.Variable.Type
        , volumes = [] : List volumes.Volume.Type
        , service = None services.Service.Type
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

let mkContainer
    : Text -> Container.Type -> kubernetes.Container.Type
    = \(appName : Text) ->
      \(container : Container.Type) ->
        kubernetes.Container::{
        , image = Some container.image
        , name = Prelude.Optional.default Text appName container.name
        , volumeMounts =
            util.mapEmpty
              volumes.Volume.Type
              kubernetes.VolumeMount.Type
              volumes.mkVolumeMount
              container.volumes
        , livenessProbe =
            Prelude.Optional.concatMap
              services.Service.Type
              kubernetes.Probe.Type
              services.mkLivenessProbe
              container.service
        , command = util.listOptional Text container.command
        , args = util.listOptional Text container.args
        , ports =
            Prelude.Optional.map
              services.Service.Type
              (List kubernetes.ContainerPort.Type)
              services.mkContainerPorts
              container.service
        , env =
            util.listOptional
              kubernetes.EnvVar.Type
              ( Prelude.List.map
                  env.Variable.Type
                  kubernetes.EnvVar.Type
                  env.mkVariable
                  container.env
              )
        , envFrom =
            Prelude.Optional.map
              storage.Bucket.Type
              (List kubernetes.EnvFromSource.Type)
              ( \(bucket : storage.Bucket.Type) ->
                  [ kubernetes.EnvFromSource::{
                    , configMapRef = Some kubernetes.ConfigMapEnvSource::{
                      , name = Some bucket.name
                      }
                    }
                  , kubernetes.EnvFromSource::{
                    , secretRef = Some kubernetes.SecretEnvSource::{
                      , name = Some bucket.name
                      }
                    }
                  ]
              )
              container.bucket
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

let mkDeployment
    : App.Type -> typesUnion
    = \(app : App.Type) ->
        let deployment =
              kubernetes.Deployment::{
              , metadata = kubernetes.ObjectMeta::{
                , name = Some (mkFullName app)
                , labels = Some (mkLabels app)
                }
              , spec = Some kubernetes.DeploymentSpec::{
                , replicas = Some app.replicas
                , selector = kubernetes.LabelSelector::{
                  , matchLabels = Some (mkLabels app)
                  }
                , template = kubernetes.PodTemplateSpec::{
                  , metadata = Some kubernetes.ObjectMeta::{
                    , labels = Some (mkLabels app)
                    }
                  , spec = Some kubernetes.PodSpec::{
                    , containers =
                        Prelude.List.map
                          Container.Type
                          kubernetes.Container.Type
                          (mkContainer app.name)
                          app.containers
                    , volumes =
                        util.mapEmpty
                          volumes.Volume.Type
                          kubernetes.Volume.Type
                          volumes.mkVolumeSource
                          ( Prelude.List.concatMap
                              Container.Type
                              volumes.Volume.Type
                              ( \(container : Container.Type) ->
                                  container.volumes
                              )
                              app.containers
                          )
                    , nodeName = app.nodeName
                    , securityContext =
                        Prelude.Optional.map
                          Natural
                          kubernetes.PodSecurityContext.Type
                          ( \(user : Natural) ->
                              kubernetes.PodSecurityContext::{
                              , runAsUser = Some user
                              , runAsGroup = Some user
                              , fsGroup = Some user
                              }
                          )
                          app.user
                    }
                  }
                }
              }

        in  typesUnion.Kubernetes (kubernetes.Resource.Deployment deployment)

let mkService
    : services.Service.Type -> App.Type -> typesUnion
    = \(service : services.Service.Type) ->
      \(app : App.Type) ->
        let service =
              kubernetes.Service::{
              , metadata = kubernetes.ObjectMeta::{
                , name = Some (mkFullName app)
                , labels = Some (mkLabels app)
                }
              , spec = Some kubernetes.ServiceSpec::{
                , selector = Some (mkLabels app)
                , ports = Some (services.mkServicePorts service)
                }
              }

        in  typesUnion.Kubernetes (kubernetes.Resource.Service service)

in  { App, Container, mkLabels, mkFullName, mkDeployment, mkService }
