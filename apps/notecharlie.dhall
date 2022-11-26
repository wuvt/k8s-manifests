let lib = ../lib.dhall

let blockStorage = ../rook/blockStorage.dhall

let secret = ../secrets/notecharlie.dhall

let block =
      lib.storage.Block::{
      , name = "pv-claim"
      , store = blockStorage
      , size = "20Mi"
      }

let app =
      lib.app.App::{
      , name = "notecharlie"
      , replicas = 1
      , user = Some 200
      , containers =
        [ lib.app.Container::{
          , image = "ghcr.io/wuvt/notecharlie:latest"
          , volumes =
            [ lib.storage.Volume::{
              , name = "notecharlie-data"
              , mountPath = "/home/bot/.phenny"
              , source =
                  lib.storage.VolumeSource.BlockStorage
                    lib.storage.BlockStorageSource::{ block }
              }
            , lib.storage.Volume::{
              , name = "notecharlie-config"
              , mountPath = "/home/bot/.phenny/default.py"
              , subPath = Some "default.py"
              , readOnly = Some True
              , source =
                  lib.storage.VolumeSource.Secret
                    lib.storage.SecretSource::{ secret }
              }
            , lib.storage.Volume::{
              , name = "tzinfo"
              , mountPath = "/etc/localtime"
              , readOnly = Some True
              , source =
                  lib.storage.VolumeSource.TZInfo lib.storage.TZInfoSource::{=}
              }
            ]
          }
        ]
      }

in  [ lib.mkBlockStorageClaim block app, lib.mkDeployment app ]
