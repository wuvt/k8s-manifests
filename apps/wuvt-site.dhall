let lib = ../lib.dhall

let configSecret = ../secrets/wuvt-site-config-am.dhall

let redisSecret = ../secrets/wuvt-site-redis-am.dhall

let service = lib.networking.Service::{ name = Some "http", port = 8080 }

let ingress = lib.networking.Ingress::{ service, host = "am.wuvt.vt.edu" }

let block = lib.storage.Block::{ size = "10Gi" }

let app =
      lib.app.App::{
      , name = "wuvt-site"
      , instance = Some "am"
      , replicas = 2
      , containers =
        [ lib.app.Container::{
          , image = "ghcr.io/wuvt/wuvt-site:latest"
          , args = [ "uwsgi", "--ini", "/data/config/uwsgi.ini" ]
          , volumes =
            [ lib.storage.Volume::{
              , name = "config"
              , mountPath = "/data/config"
              , readOnly = Some True
              , source =
                  lib.storage.VolumeSource.Secret
                    lib.storage.SecretSource::{ secret = configSecret }
              }
            , lib.storage.Volume::{
              , name = "media"
              , mountPath = "/data/media"
              , source =
                  lib.storage.VolumeSource.BlockStorage
                    lib.storage.BlockStorageSource::{ block }
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
          , service = Some service
          }
        ]
      }

let redisService = lib.networking.Service::{ name = Some "redis", port = 6379 }

let redisBlock = lib.storage.Block::{ size = "1Gi" }

let redis =
      lib.app.App::{
      , name = "wuvt-site-redis"
      , instance = Some "am"
      , replicas = 1
      , containers =
        [ lib.app.Container::{
          , image = "redis:4-alpine"
          , args =
            [ "--requirepass \$(REDIS_PASSWORD)"
            , "--rename-command CONFIG \"\""
            , "--appendonly yes"
            ]
          , volumes =
            [ lib.storage.Volume::{
              , name = "redis-data"
              , mountPath = "/data"
              , source =
                  lib.storage.VolumeSource.BlockStorage
                    lib.storage.BlockStorageSource::{ block = redisBlock }
              }
            ]
          , env =
            [ lib.app.Variable::{
              , name = "REDIS_PASSWORD"
              , source =
                  lib.app.VariableSource.Secret
                    lib.app.SecretSource::{
                    , secret = redisSecret
                    , key = "password"
                    }
              }
            ]
          , service = Some redisService
          }
        ]
      }

in  [ lib.mkService service app
    , lib.mkIngress ingress app
    , lib.mkBlockStorageClaim block app
    , lib.mkDeployment app
    , lib.mkService redisService redis
    , lib.mkBlockStorageClaim redisBlock redis
    , lib.mkDeployment redis
    ]
