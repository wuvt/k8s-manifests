let lib = ../lib.dhall

let blockStorage = ../rook/blockStorage.dhall

let configSecret = ../secrets/trackman-config-am.dhall

let nginxSecret = ../secrets/trackman-nginx-am.dhall

let redisSecret = ../secrets/trackman-redis-am.dhall

let redisCacheSecret = ../secrets/trackman-redis-cache-am.dhall

let service = lib.networking.Service::{ name = Some "http", port = 80 }

let ingress =
      lib.networking.Ingress::{ service, host = "trackman-am.apps.wuvt.vt.edu" }

let app =
      lib.app.App::{
      , name = "trackman"
      , instance = Some "am"
      , replicas = 2
      , containers =
        [ lib.app.Container::{
          , name = Some "trackman"
          , image = "ghcr.io/wuvt/trackman:latest"
          , volumes =
            [ lib.storage.Volume::{
              , name = "trackman-am-config"
              , mountPath = "/data/config"
              , readOnly = Some True
              , source =
                  lib.storage.VolumeSource.Secret
                    lib.storage.SecretSource::{ secret = configSecret }
              }
            ]
          , env =
            [ lib.app.Variable::{
              , name = "APP_CONFIG_PATH"
              , source = lib.app.VariableSource.Value "/data/config/config.json"
              }
            , lib.app.Variable::{
              , name = "TZ"
              , source = lib.app.VariableSource.Value "America/New_York"
              }
            ]
          }
        , lib.app.Container::{
          , name = Some "nginx"
          , image = "ghcr.io/wuvt/trackman-nginx:latest"
          , volumes =
            [ lib.storage.Volume::{
              , name = "trackman-am-nginx-config"
              , mountPath = "/etc/nginx/conf.d"
              , readOnly = Some True
              , source =
                  lib.storage.VolumeSource.Secret
                    lib.storage.SecretSource::{ secret = nginxSecret }
              }
            ]
          , service = Some service
          }
        ]
      }

let scheduler =
      lib.app.App::{
      , name = "trackman-scheduler"
      , instance = Some "am"
      , containers =
        [ lib.app.Container::{
          , image = "ghcr.io/wuvt/trackman:latest"
          , command = [ "flask", "run-scheduler" ]
          , volumes =
            [ lib.storage.Volume::{
              , name = "trackman-am-config"
              , mountPath = "/data/config"
              , readOnly = Some True
              , source =
                  lib.storage.VolumeSource.Secret
                    lib.storage.SecretSource::{ secret = configSecret }
              }
            ]
          , env =
            [ lib.app.Variable::{
              , name = "APP_CONFIG_PATH"
              , source = lib.app.VariableSource.Value "/data/config/config.json"
              }
            , lib.app.Variable::{
              , name = "TZ"
              , source = lib.app.VariableSource.Value "America/New_York"
              }
            ]
          }
        ]
      }

let redisService = lib.networking.Service::{ name = Some "redis", port = 6379 }

let redisBlock =
      lib.storage.Block::{
      , name = "pv-claim"
      , store = blockStorage
      , size = "1Gi"
      }

let redis =
      lib.app.App::{
      , name = "trackman-redis"
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

let redisCache =
      lib.app.App::{
      , name = "trackman-redis-cache"
      , instance = Some "am"
      , replicas = 1
      , containers =
        [ lib.app.Container::{
          , image = "redis:4-alpine"
          , args =
            [ "--requirepass \$(REDIS_PASSWORD)"
            , "--rename-command CONFIG \"\""
            ]
          , env =
            [ lib.app.Variable::{
              , name = "REDIS_PASSWORD"
              , source =
                  lib.app.VariableSource.Secret
                    lib.app.SecretSource::{
                    , secret = redisCacheSecret
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
    , lib.mkDeployment app
    , lib.mkDeployment scheduler
    , lib.mkService redisService redis
    , lib.mkBlockStorageClaim redisBlock redis
    , lib.mkDeployment redis
    , lib.mkService redisService redisCache
    , lib.mkDeployment redisCache
    ]
