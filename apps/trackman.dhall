let lib = ../lib.dhall

let kubernetes = ../kubernetes.dhall

let template = ../appTemplates/trackman.dhall

let templateRedis = ../appTemplates/redis.dhall

let configAMSecret = ../secrets/trackman-config-am.dhall

let nginxAMSecret = ../secrets/trackman-nginx-am.dhall

let tlsAMSecret = ../secrets/trackman-tls-am.dhall

let serviceAM = lib.networking.Service::{ name = Some "https", port = 8443 }

let ingressAM =
      lib.networking.Ingress::{
      , service = serviceAM
      , host = "trackman-am.apps.wuvt.vt.edu"
      , tls = True
      , tlsSecret = Some tlsAMSecret
      , httpsBackend = True
      }

let appAM =
      template.mkTrackmanApp
        { instance = "am"
        , service = serviceAM
        , configSecret = configAMSecret
        , nginxSecret = nginxAMSecret
        , tlsSecret = tlsAMSecret
        }

let schedulerAM =
      template.mkTrackmanSchedulerApp
        { instance = "am", configSecret = configAMSecret }

let redisAMSecret = ../secrets/trackman-redis-am.dhall

let redisAMCacheSecret = ../secrets/trackman-redis-cache-am.dhall

let redisAMService =
      lib.networking.Service::{ name = Some "redis", port = 6379 }

let redisAMBlock = lib.storage.Block::{ size = "1Gi" }

let redisAM =
      templateRedis.mkRedisApp
        { name = "trackman-redis"
        , instance = "am"
        , block = redisAMBlock
        , service = redisAMService
        , redisSecret = redisAMSecret
        }

let redisAMCache =
      templateRedis.mkRedisCacheApp
        { name = "trackman-redis-cache"
        , instance = "am"
        , service = redisAMService
        , redisSecret = redisAMCacheSecret
        }

let configFMSecret = ../secrets/trackman-config-fm.dhall

let nginxFMSecret = ../secrets/trackman-nginx-fm.dhall

let tlsFMSecret = ../secrets/trackman-tls-fm.dhall

let serviceFM = lib.networking.Service::{ name = Some "https", port = 8443 }

let ingressFM =
      lib.networking.Ingress::{
      , service = serviceFM
      , host = "trackman-fm.apps.wuvt.vt.edu"
      , tls = True
      , tlsSecret = Some tlsFMSecret
      , httpsBackend = True
      }

let appFM =
      template.mkTrackmanApp
        { instance = "fm"
        , service = serviceFM
        , configSecret = configFMSecret
        , nginxSecret = nginxFMSecret
        , tlsSecret = tlsFMSecret
        }

let schedulerFM =
      template.mkTrackmanSchedulerApp
        { instance = "fm", configSecret = configFMSecret }

let redisFMSecret = ../secrets/trackman-redis-fm.dhall

let redisFMCacheSecret = ../secrets/trackman-redis-cache-fm.dhall

let redisFMService =
      lib.networking.Service::{ name = Some "redis", port = 6379 }

let redisFMBlock = lib.storage.Block::{ size = "1Gi" }

let redisFM =
      templateRedis.mkRedisApp
        { name = "trackman-redis"
        , instance = "fm"
        , block = redisFMBlock
        , service = redisFMService
        , redisSecret = redisFMSecret
        }

let redisFMCache =
      templateRedis.mkRedisCacheApp
        { name = "trackman-redis-cache"
        , instance = "fm"
        , service = redisFMService
        , redisSecret = redisFMCacheSecret
        }

in  [ lib.mkService serviceAM appAM
    , lib.mkIngress ingressAM appAM
    , lib.mkDeployment appAM
    , lib.mkDeployment schedulerAM
    , lib.mkService redisAMService redisAM
    , lib.mkBlockStorageClaim redisAMBlock redisAM
    , lib.mkDeployment redisAM
    , lib.mkService redisAMService redisAMCache
    , lib.mkDeployment redisAMCache
    , lib.mkService serviceFM appFM
    , lib.mkIngress ingressFM appFM
    , lib.mkDeployment appFM
    , lib.mkDeployment schedulerFM
    , lib.mkService redisFMService redisFM
    , lib.mkBlockStorageClaim redisFMBlock redisFM
    , lib.mkDeployment redisFM
    , lib.mkService redisFMService redisFMCache
    , lib.mkDeployment redisFMCache
    ]
