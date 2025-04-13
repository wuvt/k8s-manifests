let kubernetes = ../kubernetes.dhall

let secret =
      kubernetes.Secret::{
      , metadata = kubernetes.ObjectMeta::{ name = Some "trackman-redis-am" }
      , type = Some "Opaque"
      , stringData = Some
          ( toMap
              { password =
                  ./k8s-secrets/secrets/trackman/redis-am/password.txt as Text
              }
          )
      }

in  secret
