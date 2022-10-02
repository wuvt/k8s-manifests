let Prelude = ../Prelude.dhall

let kubernetes = ../kubernetes.dhall

let env = ./env.dhall

let services = ./services.dhall

let storage = ./storage.dhall

let typesUnion = ./typesUnion.dhall

let util = ./util.dhall

let volumes = ./volumes.dhall

let App =
      { Type =
          { name : Text
          , replicas : Natural
          , image : Text
          , args : List Text
          , env : List env.Variable.Type
          , volumes : List volumes.Volume.Type
          , user : Optional Natural
          , nodeName : Optional Text
          , service : Optional services.Service
          , bucket : Optional storage.Bucket.Type
          }
      , default =
        { replicas = 1
        , args = [] : List Text
        , env = [] : List env.Variable.Type
        , volumes = [] : List volumes.Volume.Type
        , user = None Natural
        , nodeName = None Text
        , service = None services.Service
        , bucket = None storage.Bucket.Type
        }
      }

let mkDeployment
    : App.Type -> typesUnion
    = \(app : App.Type) ->
        let deployment =
              kubernetes.Deployment::{
              , metadata = kubernetes.ObjectMeta::{
                , name = Some app.name
                , labels = Some (toMap { `app.kubernetes.io/name` = app.name })
                }
              , spec = Some kubernetes.DeploymentSpec::{
                , replicas = Some app.replicas
                , selector = kubernetes.LabelSelector::{
                  , matchLabels = Some
                      (toMap { `app.kubernetes.io/name` = app.name })
                  }
                , template = kubernetes.PodTemplateSpec::{
                  , metadata = Some kubernetes.ObjectMeta::{
                    , labels = Some
                        (toMap { `app.kubernetes.io/name` = app.name })
                    }
                  , spec = Some kubernetes.PodSpec::{
                    , containers =
                      [ kubernetes.Container::{
                        , image = Some app.image
                        , name = app.name
                        , volumeMounts =
                            util.mapEmpty
                              volumes.Volume.Type
                              kubernetes.VolumeMount.Type
                              volumes.mkVolumeMount
                              app.volumes
                        , livenessProbe =
                            Prelude.Optional.concatMap
                              services.Service
                              kubernetes.Probe.Type
                              services.mkLivenessProbe
                              app.service
                        , args = util.listOptional Text app.args
                        , ports =
                            Prelude.Optional.map
                              services.Service
                              (List kubernetes.ContainerPort.Type)
                              services.mkContainerPorts
                              app.service
                        , env =
                            util.listOptional
                              kubernetes.EnvVar.Type
                              ( Prelude.List.map
                                  env.Variable.Type
                                  kubernetes.EnvVar.Type
                                  env.mkVariable
                                  app.env
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
                              app.bucket
                        }
                      ]
                    , volumes =
                        util.mapEmpty
                          volumes.Volume.Type
                          kubernetes.Volume.Type
                          volumes.mkVolumeSource
                          app.volumes
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
    : services.Service -> App.Type -> typesUnion
    = \(service : services.Service) ->
      \(app : App.Type) ->
        let service =
              kubernetes.Service::{
              , metadata = kubernetes.ObjectMeta::{
                , name = Some app.name
                , labels = Some (toMap { `app.kubernetes.io/name` = app.name })
                }
              , spec = Some kubernetes.ServiceSpec::{
                , selector = Some
                    (toMap { `app.kubernetes.io/name` = app.name })
                , ports = Some (services.mkServicePorts service)
                }
              }

        in  typesUnion.Kubernetes (kubernetes.Resource.Service service)

in  { App, mkDeployment, mkService }
