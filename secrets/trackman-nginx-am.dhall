let kubernetes = ../kubernetes.dhall

let secret =
      kubernetes.Secret::{
      , metadata = kubernetes.ObjectMeta::{ name = Some "trackman-nginx-am" }
      , type = Some "Opaque"
      , stringData = Some
          (toMap { `default.conf` = ./trackman/nginx-am/default.conf as Text })
      }

in  secret
