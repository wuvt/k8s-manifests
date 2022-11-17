let kubernetes = ../kubernetes.dhall

let secret =
      kubernetes.Secret::{
      , metadata = kubernetes.ObjectMeta::{ name = Some "metadater-config" }
      , type = Some "Opaque"
      , stringData = Some
          (toMap { `config.json` = ./metadater/config.json as Text })
      }

in  secret