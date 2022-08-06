let kubernetes = ../kubernetes.dhall

let lib = ../lib.dhall

let blockStorage = ../rook/blockStorage.dhall

let secret = ../secrets/notecharlie.dhall

let blockClaim =
      lib.storage.PersistentBlockClaim::{
      , name = "notecharlie-pv-claim"
      , appName = Some "notecharlie"
      , size = "10Mi"
      }

let app =
      lib.app.App::{
      , name = "notecharlie"
      , replicas = 1
      , image = "ghcr.io/wuvt/notecharlie:latest"
      , volumes =
        [ lib.volumes.Volume::{
          , name = "notecharlie-data"
          , mountPath = "/home/bot/.phenny"
          , source =
              lib.volumes.VolumeSource.BlockStorage
                lib.volumes.BlockStorageSource::{ claim = blockClaim }
          }
        , lib.volumes.Volume::{
          , name = "notecharlie-config"
          , mountPath = "/home/bot/.phenny/default.py"
          , subPath = Some "default.py"
          , readOnly = Some True
          , source =
              lib.volumes.VolumeSource.Secret
                lib.volumes.SecretSource::{ secret }
          }
        , lib.volumes.Volume::{
          , name = "tzinfo"
          , mountPath = "/etc/localtime"
          , readOnly = Some True
          , source =
              lib.volumes.VolumeSource.TZInfo lib.volumes.TZInfoSource::{=}
          }
        ]
      }

in  [ kubernetes.Resource.PersistentVolumeClaim
        (blockStorage.mkClaim blockClaim)
    , kubernetes.Resource.Deployment (lib.app.mkDeployment app)
    ]
