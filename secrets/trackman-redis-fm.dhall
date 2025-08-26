let kubernetes = ../kubernetes.dhall

let secret =
      kubernetes.Secret::{
      , metadata = kubernetes.ObjectMeta::{ name = Some "trackman-redis-fm" }
      , type = Some "Opaque"
      , stringData = Some
          ( toMap
              { password =
                  ./k8s-secrets/secrets/trackman/redis-fm/password.txt as Text
              }
          )
      }

in  secret
