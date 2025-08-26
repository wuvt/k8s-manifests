let lib = ../lib.dhall

let kubernetes = ../kubernetes.dhall

let mkWuvtSiteApp
    : { instance : Text
      , block : lib.storage.Block.Type
      , service : lib.networking.Service.Type
      , configSecret : kubernetes.Secret.Type
      , tlsSecret : kubernetes.Secret.Type
      } ->
        lib.app.App.Type
    = \ ( params
        : { instance : Text
          , block : lib.storage.Block.Type
          , service : lib.networking.Service.Type
          , configSecret : kubernetes.Secret.Type
          , tlsSecret : kubernetes.Secret.Type
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
                , name = "tls"
                , mountPath = "/data/tls"
                , readOnly = Some True
                , source =
                    lib.storage.VolumeSource.Secret
                      lib.storage.SecretSource::{ secret = params.tlsSecret }
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

in  { mkWuvtSiteApp }
