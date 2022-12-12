let kubernetes = ../kubernetes.dhall

let secret =
      kubernetes.Secret::{
      , metadata = kubernetes.ObjectMeta::{ name = Some "wuvt-site-redis-am" }
      , type = Some "Opaque"
      , stringData = Some
          (toMap { password = ./wuvt-site/redis-am/password.txt as Text })
      }

in  secret
