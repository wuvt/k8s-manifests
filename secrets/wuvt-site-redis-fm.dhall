let kubernetes = ../kubernetes.dhall

let secret =
      kubernetes.Secret::{
      , metadata = kubernetes.ObjectMeta::{ name = Some "wuvt-site-redis-fm" }
      , type = Some "Opaque"
      , stringData = Some
          ( toMap
              { password =
                  ./k8s-secrets/secrets/wuvt-site/redis-fm/password.txt as Text
              }
          )
      }

in  secret
