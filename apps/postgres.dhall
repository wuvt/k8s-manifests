let lib = ../lib.dhall

let secret = ../secrets/postgres.dhall

let service = lib.services.Service::{ port = 5432 }

let app =
      lib.app.App::{
      , name = "postgres"
      , replicas = 1
      , nodeName = Some "falcon9"
      , containers =
        [ lib.app.Container::{
          , image = "ghcr.io/wuvt/postgres:latest"
          , volumes =
            [ lib.volumes.Volume::{
              , name = "postgres-data"
              , mountPath = "/var/lib/postgresql/data"
              , source =
                  lib.volumes.VolumeSource.Host
                    lib.volumes.HostSource::{
                    , path = "/media/local-storage/postgres-data"
                    }
              }
            ]
          , env =
            [ lib.env.Variable::{
              , name = "POSTGRES_PASSWORD"
              , source =
                  lib.env.VariableSource.Secret
                    lib.env.SecretSource::{ secret, key = "password" }
              }
            ]
          , service = Some service
          }
        ]
      }

in  [ lib.app.mkService service app, lib.app.mkDeployment app ]
