let kubernetes = ../kubernetes.dhall

let storage = ../rook/storage.dhall

let blockClaim =
      storage.PersistentBlockClaim::{
      , name = "notecharlie-pv-claim"
      , appName = Some "notecharlie"
      , size = "10Mi"
      }

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
                    , name = "notecharlie-data"
                    , mountPath = "/home/bot/.phenny"
                    }
                  , kubernetes.VolumeMount::{
                    , name = "notecharlie-config"
                    , mountPath = "/home/bot/.phenny/default.py"
                    , subPath = Some "default.py"
                    , readOnly = Some True
                    }
                  , kubernetes.VolumeMount::{
                    , name = "tzinfo"
                    , mountPath = "/etc/localtime"
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
                , name = "notecharlie-data"
                , persistentVolumeClaim = Some kubernetes.PersistentVolumeClaimVolumeSource::{
                  , claimName = "notecharlie-pv-claim"
                  }
                }
              , kubernetes.Volume::{
                , name = "tzinfo"
                , hostPath = Some kubernetes.HostPathVolumeSource::{
                  , path = "/usr/share/zoneinfo/America/New_York"
                  }
                }
              ]
            }
          }
        }
      }

in  [ kubernetes.Resource.PersistentVolumeClaim (storage.mkClaim blockClaim)
    , kubernetes.Resource.Deployment deployment
    ]
