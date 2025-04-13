let kubernetes = ../kubernetes.dhall

let secret =
      kubernetes.Secret::{
      , metadata = kubernetes.ObjectMeta::{ name = Some "oauth2-proxy-config" }
      , type = Some "Opaque"
      , stringData = Some
          ( toMap
              { `oauth2-proxy.cfg` =
                  ./k8s-secrets/secrets/oauth2-proxy/oauth2-proxy.cfg as Text
              }
          )
      }

in  secret
