let lib = ../lib.dhall

let secret = ../secrets/metadater.dhall

let app =
      lib.app.App::{
      , name = "metadater"
      , replicas = 1
      , containers =
        [ lib.app.Container::{
          , image = "ghcr.io/wuvt/metadater:go-rewrite"
          , volumes =
            [ lib.storage.Volume::{
              , name = "metadater-config"
              , mountPath = "/etc/metadater"
              , readOnly = Some True
              , source =
                  lib.storage.VolumeSource.Secret
                    lib.storage.SecretSource::{ secret }
              }
            ]
          }
        ]
      }

in  [ lib.mkDeployment app ]
