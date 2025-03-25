let lib = ../lib.dhall

let secret = ../secrets/mediawiki.dhall

let imagesBlock = lib.storage.Block::{ name = "wiki-images", size = "5Gi" }

let dbBlock = lib.storage.Block::{ name = "wiki-db", size = "5Gi" }

let service = lib.networking.Service::{ name = Some "http", port = 80 }

let ingress =
      lib.networking.Ingress::{
      , service
      , host = "engineering-wiki.apps.wuvt.vt.edu"
      , authenticated = True
      }

let app =
      lib.app.App::{
      , name = "engineering-wiki"
      , replicas = 1
      , containers =
        [ lib.app.Container::{
          , image = "mediawiki:latest"
          , service = Some service
          , env =
            [ lib.app.Variable::{
              , name = "MEDIAWIKI_SERVER"
              , source =
                  lib.app.VariableSource.Value
                    "https://engineering-wiki.apps.wuvt.vt.edu"
              }
            , lib.app.Variable::{
              , name = "MEDIAWIKI_DB_TYPE"
              , source = lib.app.VariableSource.Value "sqlite"
              }
            , lib.app.Variable::{
              , name = "TZ"
              , source = lib.app.VariableSource.Value "America/New_York"
              }
            ]
          , volumes =
            [ lib.storage.Volume::{
              , name = "mediawiki-data"
              , mountPath = "/var/www/html/images"
              , source =
                  lib.storage.VolumeSource.BlockStorage
                    lib.storage.BlockStorageSource::{ block = imagesBlock }
              }
            , lib.storage.Volume::{
              , name = "mediawiki-db"
              , mountPath = "/var/www/data"
              , source =
                  lib.storage.VolumeSource.BlockStorage
                    lib.storage.BlockStorageSource::{ block = dbBlock }
              }
            , lib.storage.Volume::{
              , name = "mediawiki-config"
              , mountPath = "/var/www/html/LocalSettings.php"
              , subPath = Some "LocalSettings.php"
              , readOnly = Some True
              , source =
                  lib.storage.VolumeSource.Secret
                    lib.storage.SecretSource::{ secret }
              }
            ]
          }
        ]
      }

in  [ lib.mkService service app
    , lib.mkBlockStorageClaim imagesBlock app
    , lib.mkBlockStorageClaim dbBlock app
    , lib.mkIngress ingress app
    , lib.mkDeployment app
    ]
