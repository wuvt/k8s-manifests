let Prelude = ../Prelude.dhall

let kubernetes = ../kubernetes.dhall

let volumes = ./volumes.dhall

let util = ./util.dhall

let App =
      { Type =
          { name : Text
          , replicas : Natural
          , image : Text
          , volumes : List volumes.Volume.Type
          , user : Optional Natural
          }
      , default =
        { replicas = 1
        , volumes = [] : List volumes.Volume.Type
        , user = None Natural
        }
      }

let mkDeployment
    : App.Type -> kubernetes.Deployment.Type
    = \(app : App.Type) ->
        kubernetes.Deployment::{
        , metadata = kubernetes.ObjectMeta::{
          , name = Some app.name
          , labels = Some (toMap { `app.kubernetes.io/name` = app.name })
          }
        , spec = Some kubernetes.DeploymentSpec::{
          , replicas = Some app.replicas
          , selector = kubernetes.LabelSelector::{
            , matchLabels = Some (toMap { `app.kubernetes.io/name` = app.name })
            }
          , template = kubernetes.PodTemplateSpec::{
            , metadata = Some kubernetes.ObjectMeta::{
              , labels = Some (toMap { `app.kubernetes.io/name` = app.name })
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
                  }
                ]
              , volumes =
                  util.mapEmpty
                    volumes.Volume.Type
                    kubernetes.Volume.Type
                    volumes.mkVolumeSource
                    app.volumes
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

in  { App, mkDeployment }
