let kubernetes = ../kubernetes.dhall

let secret =
      kubernetes.Secret::{
      , metadata = kubernetes.ObjectMeta::{ name = Some "pload-fm-config" }
      , type = Some "Opaque"
      , stringData = Some
          ( toMap
              { `config.json` =
                  ./k8s-secrets/secrets/pload-fm/config.json as Text
              , id_ed25519 = ./k8s-secrets/secrets/pload-fm/id_ed25519 as Text
              , `id_ed25519.pub` =
                  ./k8s-secrets/secrets/pload-fm/id_ed25519.pub as Text
              , known_hosts = ./k8s-secrets/secrets/pload-fm/known_hosts as Text
              }
          )
      }

in  secret
