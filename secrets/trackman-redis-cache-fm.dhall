let kubernetes = ../kubernetes.dhall

let secret =
      kubernetes.Secret::{
      , metadata = kubernetes.ObjectMeta::{
        , name = Some "trackman-redis-cache-fm"
        }
      , type = Some "Opaque"
      , stringData = Some
          ( toMap
              { password =
                  ./k8s-secrets/secrets/trackman/redis-cache-fm/password.txt as Text
              }
          )
      }

in  secret
