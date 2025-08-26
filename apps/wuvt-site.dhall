let lib = ../lib.dhall

let kubernetes = ../kubernetes.dhall

let template = ../appTemplates/wuvt-site.dhall

let templateRedis = ../appTemplates/redis.dhall

let configAMSecret = ../secrets/wuvt-site-config-am.dhall

let tlsAMSecret = ../secrets/wuvt-site-tls-am.dhall

let serviceAM = lib.networking.Service::{ name = Some "https", port = 8443 }

let ingressAM =
      lib.networking.Ingress::{
      , service = serviceAM
      , host = "am.wuvt.vt.edu"
      , tls = True
      , tlsSecret = Some tlsAMSecret
      , httpsBackend = True
      }

let blockAM = lib.storage.Block::{ size = "10Gi" }

let appAM =
      template.mkWuvtSiteApp
        { instance = "am"
        , block = blockAM
        , service = serviceAM
        , configSecret = configAMSecret
        , tlsSecret = tlsAMSecret
        }

let redisAMSecret = ../secrets/wuvt-site-redis-am.dhall

let redisAMService =
      lib.networking.Service::{ name = Some "redis", port = 6379 }

let redisAMBlock = lib.storage.Block::{ size = "1Gi" }

let redisAM =
      templateRedis.mkRedisApp
        { name = "wuvt-site-redis"
        , instance = "am"
        , block = redisAMBlock
        , service = redisAMService
        , redisSecret = redisAMSecret
        }

let configFMSecret = ../secrets/wuvt-site-config-fm.dhall

let tlsFMSecret = ../secrets/wuvt-site-tls-fm.dhall

let serviceFM = lib.networking.Service::{ name = Some "https", port = 8443 }

let ingressFM =
      lib.networking.Ingress::{
      , service = serviceFM
      , host = "www.wuvt.vt.edu"
      , tls = True
      , tlsSecret = Some tlsFMSecret
      , httpsBackend = True
      }

let blockFM = lib.storage.Block::{ size = "10Gi" }

let appFM =
      template.mkWuvtSiteApp
        { instance = "fm"
        , block = blockFM
        , service = serviceFM
        , configSecret = configFMSecret
        , tlsSecret = tlsFMSecret
        }

let redisFMSecret = ../secrets/wuvt-site-redis-fm.dhall

let redisFMService =
      lib.networking.Service::{ name = Some "redis", port = 6379 }

let redisFMBlock = lib.storage.Block::{ size = "1Gi" }

let redisFM =
      templateRedis.mkRedisApp
        { name = "wuvt-site-redis"
        , instance = "fm"
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
