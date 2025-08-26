let lib = ../lib.dhall

let kubernetes = ../kubernetes.dhall

let mkRedisApp
    : { name : Text
      , instance : Text
      , block : lib.storage.Block.Type
      , service : lib.networking.Service.Type
      , redisSecret : kubernetes.Secret.Type
      } ->
        lib.app.App.Type
    = \ ( params
        : { name : Text
          , instance : Text
          , block : lib.storage.Block.Type
          , service : lib.networking.Service.Type
          , redisSecret : kubernetes.Secret.Type
          }
        ) ->
        lib.app.App::{
        , name = params.name
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

let mkRedisCacheApp
    : { name : Text
      , instance : Text
      , service : lib.networking.Service.Type
      , redisSecret : kubernetes.Secret.Type
      } ->
        lib.app.App.Type
    = \ ( params
        : { name : Text
          , instance : Text
          , service : lib.networking.Service.Type
          , redisSecret : kubernetes.Secret.Type
          }
        ) ->
        lib.app.App::{
        , name = params.name
        , instance = Some params.instance
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
                      , secret = params.redisSecret
                      , key = "password"
                      }
                }
              ]
            , service = Some params.service
            }
          ]
        }

in  { mkRedisApp, mkRedisCacheApp }
