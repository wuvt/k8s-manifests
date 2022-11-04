let lib = ../lib.dhall

let secret = ../secrets/oauth2-proxy.dhall

let service =
      lib.networking.Service::{
      , name = Some "http"
      , port = 4180
      , livenessProbe = Some lib.networking.HTTPLivenessProbe::{
        , path = "/ping"
        , initialDelaySeconds = Some 60
        , timeoutSeconds = Some 5
        , failureThreshold = Some 5
        }
      }

let ingress =
      lib.networking.Ingress::{ service, host = "login.apps.wuvt.vt.edu" }

let app =
      lib.app.App::{
      , name = "oauth2-proxy"
      , replicas = 2
      , containers =
        [ lib.app.Container::{
          , image = "quay.io/oauth2-proxy/oauth2-proxy:latest"
          , args = [ "--config=/data/oauth2-proxy.cfg" ]
          , volumes =
            [ lib.storage.Volume::{
              , name = "oauth2-proxy-config"
              , mountPath = "/data/oauth2-proxy.cfg"
              , subPath = Some "oauth2-proxy.cfg"
              , readOnly = Some True
              , source =
                  lib.storage.VolumeSource.Secret
                    lib.storage.SecretSource::{ secret }
              }
            ]
          , service = Some service
          }
        ]
      }

in  [ lib.mkService service app
    , lib.mkIngress ingress app
    , lib.mkDeployment app
    ]
