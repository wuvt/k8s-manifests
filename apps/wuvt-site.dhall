let lib = ../lib.dhall

let kubernetes = ../kubernetes.dhall

let mkWuvtSiteApp
    : { instance : Text
      , block : lib.storage.Block.Type
      , service : lib.networking.Service.Type
      , configSecret : kubernetes.Secret.Type
      } ->
        lib.app.App.Type
    = \ ( params
        : { instance : Text
          , block : lib.storage.Block.Type
          , service : lib.networking.Service.Type
          , configSecret : kubernetes.Secret.Type
          }
        ) ->
        lib.app.App::{
        , name = "wuvt-site"
        , instance = Some params.instance
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
                      lib.storage.SecretSource::{ secret = params.configSecret }
                }
              , lib.storage.Volume::{
                , name = "media"
                , mountPath = "/data/media"
                , source =
                    lib.storage.VolumeSource.BlockStorage
                      lib.storage.BlockStorageSource::{ block = params.block }
                }
              , lib.storage.Volume::{
                , name = "tzinfo"
                , mountPath = "/etc/localtime"
                , readOnly = Some True
                , source =
                    lib.storage.VolumeSource.TZInfo
                      lib.storage.TZInfoSource::{=}
                }
              ]
            , env =
              [ lib.app.Variable::{
                , name = "APP_CONFIG_PATH"
                , source =
                    lib.app.VariableSource.Value "/data/config/config.json"
                }
              ]
            , service = Some params.service
            }
          ]
        }

let mkWuvtSiteRedisApp
    : { instance : Text
      , block : lib.storage.Block.Type
      , service : lib.networking.Service.Type
      , redisSecret : kubernetes.Secret.Type
      } ->
        lib.app.App.Type
    = \ ( params
        : { instance : Text
          , block : lib.storage.Block.Type
          , service : lib.networking.Service.Type
          , redisSecret : kubernetes.Secret.Type
          }
        ) ->
        lib.app.App::{
        , name = "wuvt-site-redis"
        , instance = Some params.instance
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
                      lib.storage.BlockStorageSource::{ block = params.block }
                }
              ]
            , env =
              [ lib.app.Variable::{
                , name = "REDIS_PASSWORD"
                , source =
                    lib.app.VariableSource.Secret
                      lib.app.SecretSource::{
                      , secret = params.redisSecret
                      , key = "password"
                      }
                }
              ]
            , service = Some params.service
            }
          ]
        }

let configAMSecret = ../secrets/wuvt-site-config-am.dhall

let serviceAM = lib.networking.Service::{ name = Some "http", port = 8080 }

let ingressAM =
      lib.networking.Ingress::{ service = serviceAM, host = "am.wuvt.vt.edu" }

let blockAM = lib.storage.Block::{ size = "10Gi" }

let appAM =
      mkWuvtSiteApp
        { instance = "am"
        , block = blockAM
        , service = serviceAM
        , configSecret = configAMSecret
        }

let redisAMSecret = ../secrets/wuvt-site-redis-am.dhall

let redisAMService =
      lib.networking.Service::{ name = Some "redis", port = 6379 }

let redisAMBlock = lib.storage.Block::{ size = "1Gi" }

let redisAM =
      mkWuvtSiteRedisApp
        { instance = "am"
        , block = redisAMBlock
        , service = redisAMService
        , redisSecret = redisAMSecret
        }

let configFMSecret = ../secrets/wuvt-site-config-fm.dhall

let serviceFM = lib.networking.Service::{ name = Some "http", port = 8080 }

let ingressFM =
      lib.networking.Ingress::{ service = serviceFM, host = "www.wuvt.vt.edu" }

let blockFM = lib.storage.Block::{ size = "10Gi" }

let appFM =
      mkWuvtSiteApp
        { instance = "fm"
        , block = blockFM
        , service = serviceFM
        , configSecret = configFMSecret
        }

let redisFMSecret = ../secrets/wuvt-site-redis-fm.dhall

let redisFMService =
      lib.networking.Service::{ name = Some "redis", port = 6379 }

let redisFMBlock = lib.storage.Block::{ size = "1Gi" }

let redisFM =
      mkWuvtSiteRedisApp
        { instance = "fm"
        , block = redisFMBlock
        , service = redisFMService
        , redisSecret = redisFMSecret
        }

in  [ lib.mkService serviceAM appAM
    , lib.mkIngress ingressAM appAM
    , lib.mkBlockStorageClaim blockAM appAM
    , lib.mkDeployment appAM
    , lib.mkService serviceFM appFM
    , lib.mkIngress ingressFM appFM
    , lib.mkBlockStorageClaim blockFM appFM
    , lib.mkDeployment appFM
    , lib.mkService redisAMService redisAM
    , lib.mkBlockStorageClaim redisAMBlock redisAM
    , lib.mkDeployment redisAM
    , lib.mkService redisFMService redisFM
    , lib.mkBlockStorageClaim redisFMBlock redisFM
    , lib.mkDeployment redisFM
    ]
