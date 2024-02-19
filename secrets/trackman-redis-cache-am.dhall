let kubernetes = ../kubernetes.dhall

let secret =
      kubernetes.Secret::{
      , metadata = kubernetes.ObjectMeta::{
        , name = Some "trackman-redis-cache-am"
        }
      , type = Some "Opaque"
      , stringData = Some
          (toMap { password = ./trackman/redis-cache-am/password.txt as Text })
      }

in  secret