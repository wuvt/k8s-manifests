let lib = ../lib.dhall

let kubernetes = ../kubernetes.dhall

let mkTrackmanApp
    : { instance : Text
      , service : lib.networking.Service.Type
      , configSecret : kubernetes.Secret.Type
      , nginxSecret : kubernetes.Secret.Type
      , tlsSecret : kubernetes.Secret.Type
      } ->
        lib.app.App.Type
    = \ ( params
        : { instance : Text
          , service : lib.networking.Service.Type
          , configSecret : kubernetes.Secret.Type
          , nginxSecret : kubernetes.Secret.Type
          , tlsSecret : kubernetes.Secret.Type
          }
        ) ->
        lib.app.App::{
        , name = "trackman"
        , instance = Some params.instance
        , replicas = 2
        , containers =
          [ lib.app.Container::{
            , name = Some "trackman"
            , image = "ghcr.io/wuvt/trackman:latest"
            , volumes =
              [ lib.storage.Volume::{
                , name = "config"
                , mountPath = "/data/config"
                , readOnly = Some True
                , source =
                    lib.storage.VolumeSource.Secret
                      lib.storage.SecretSource::{ secret = params.configSecret }
                }
              ]
            , env =
              [ lib.app.Variable::{
                , name = "APP_CONFIG_PATH"
                , source =
                    lib.app.VariableSource.Value "/data/config/config.json"
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
                , name = "nginx-config"
                , mountPath = "/etc/nginx/conf.d"
                , readOnly = Some True
                , source =
                    lib.storage.VolumeSource.Secret
                      lib.storage.SecretSource::{ secret = params.nginxSecret }
                }
              , lib.storage.Volume::{
                , name = "tls"
                , mountPath = "/data/tls"
                , readOnly = Some True
                , source =
                    lib.storage.VolumeSource.Secret
                      lib.storage.SecretSource::{ secret = params.tlsSecret }
                }
              ]
            , service = Some params.service
            }
          ]
        }

let mkTrackmanSchedulerApp
    : { instance : Text, configSecret : kubernetes.Secret.Type } ->
        lib.app.App.Type
    = \(params : { instance : Text, configSecret : kubernetes.Secret.Type }) ->
        lib.app.App::{
        , name = "trackman-scheduler"
        , instance = Some params.instance
        , containers =
          [ lib.app.Container::{
            , image = "ghcr.io/wuvt/trackman:latest"
            , command = [ "flask", "run-scheduler" ]
            , volumes =
              [ lib.storage.Volume::{
                , name = "config"
                , mountPath = "/data/config"
                , readOnly = Some True
                , source =
                    lib.storage.VolumeSource.Secret
                      lib.storage.SecretSource::{ secret = params.configSecret }
                }
              ]
            , env =
              [ lib.app.Variable::{
                , name = "APP_CONFIG_PATH"
                , source =
                    lib.app.VariableSource.Value "/data/config/config.json"
                }
              , lib.app.Variable::{
                , name = "TZ"
                , source = lib.app.VariableSource.Value "America/New_York"
                }
              ]
            }
          ]
        }

in  { mkTrackmanApp, mkTrackmanSchedulerApp }
