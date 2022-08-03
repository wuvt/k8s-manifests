let kubernetes = ../kubernetes.dhall

let deployment =
      kubernetes.Deployment::{
      , metadata = kubernetes.ObjectMeta::{
        , name = Some "notecharlie"
        , labels = Some (toMap { app = "notecharlie" })
        }
      , spec = Some kubernetes.DeploymentSpec::{
        , replicas = Some 1
        , selector = kubernetes.LabelSelector::{
          , matchLabels = Some (toMap { app = "notecharlie" })
          }
        , template = kubernetes.PodTemplateSpec::{
          , metadata = Some kubernetes.ObjectMeta::{
            , labels = Some (toMap { app = "notecharlie" })
            }
          , spec = Some kubernetes.PodSpec::{
            , containers =
              [ kubernetes.Container::{
                , image = Some "ghcr.io/wuvt/notecharlie:latest"
                , name = "notecharlie"
                , volumeMounts = Some
                  [ kubernetes.VolumeMount::{
                    , mountPath = "/home/bot/.phenny"
                    , name = "notecharlie-config"
                    , readOnly = Some True
                    }
                  , kubernetes.VolumeMount::{
                    , mountPath = "/etc/localtime"
                    , name = "tzinfo"
                    , readOnly = Some True
                    }
                  ]
                }
              ]
            , volumes = Some
              [ kubernetes.Volume::{
                , name = "notecharlie-config"
                , secret = Some kubernetes.SecretVolumeSource::{
                  , secretName = Some "notecharlie.config"
                  }
                }
              , kubernetes.Volume::{
                , hostPath = Some kubernetes.HostPathVolumeSource::{
                  , path = "/usr/share/zoneinfo/America/New_York"
                  }
                , name = "tzinfo"
                }
              ]
            }
          }
        }
      }

in  deployment
