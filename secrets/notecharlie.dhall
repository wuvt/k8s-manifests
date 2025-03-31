let kubernetes = ../kubernetes.dhall

let secret =
      kubernetes.Secret::{
      , metadata = kubernetes.ObjectMeta::{ name = Some "notecharlie-config" }
      , type = Some "Opaque"
      , stringData = Some
          (toMap { `default.py` = ./k8s-secrets/secrets/notecharlie/default.py as Text })
      }

in  secret
