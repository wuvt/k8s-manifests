let kubernetes = ../kubernetes.dhall

let secret =
      kubernetes.Secret::{
      , metadata = kubernetes.ObjectMeta::{ name = Some "trackman-nginx-fm" }
      , type = Some "Opaque"
      , stringData = Some
          ( toMap
              { `default.conf` =
                  ./k8s-secrets/secrets/trackman/nginx-fm/default.conf as Text
              }
          )
      }

in  secret
