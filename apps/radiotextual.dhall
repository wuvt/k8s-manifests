let lib = ../lib.dhall

let secret = ../secrets/radiotextual.dhall

let app =
      lib.app.App::{
      , name = "radiotextual"
      , replicas = 1
      , containers =
        [ lib.app.Container::{
          , image = "ghcr.io/wuvt/radiotextual:latest"
          , volumes =
            [ lib.storage.Volume::{
              , name = "radiotextual-config"
              , mountPath = "/data/config"
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
          , env =
            [ lib.app.Variable::{
              , name = "APP_CONFIG_PATH"
              , source = lib.app.VariableSource.Value "/data/config/config.json"
              }
            ]
          }
        ]
      }

in  [ lib.mkDeployment app ]
