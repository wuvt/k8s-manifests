let kubernetes = ../kubernetes.dhall

let secret =
      kubernetes.Secret::{
      , metadata = kubernetes.ObjectMeta::{ name = Some "postgres" }
      , type = Some "Opaque"
      , stringData = Some (toMap { password = ./postgres/password.txt as Text })
      }

in  secret
