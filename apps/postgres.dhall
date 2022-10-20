let lib = ../lib.dhall

let secret = ../secrets/postgres.dhall

let service = lib.networking.Service::{ port = 5432 }

let app =
      lib.app.App::{
      , name = "postgres"
      , replicas = 1
      , nodeName = Some "falcon9"
      , containers =
        [ lib.app.Container::{
          , image = "ghcr.io/wuvt/postgres:latest"
          , volumes =
            [ lib.storage.Volume::{
              , name = "postgres-data"
              , mountPath = "/var/lib/postgresql/data"
              , source =
                  lib.storage.VolumeSource.Host
                    lib.storage.HostSource::{
                    , path = "/media/local-storage/postgres-data"
                    }
              }
            ]
          , env =
            [ lib.app.Variable::{
              , name = "POSTGRES_PASSWORD"
              , source =
                  lib.app.VariableSource.Secret
                    lib.app.SecretSource::{ secret, key = "password" }
              }
            ]
          , service = Some service
          }
        ]
      }

in  [ lib.mkService service app, lib.mkDeployment app ]
