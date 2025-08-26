let kubernetes = ../kubernetes.dhall

let secret =
      kubernetes.Secret::{
      , metadata = kubernetes.ObjectMeta::{ name = Some "trackman-config-fm" }
      , type = Some "Opaque"
      , stringData = Some
          ( toMap
              { `client_secrets.json` =
                  ./k8s-secrets/secrets/trackman/config-fm/client_secrets.json as Text
              , `config.json` =
                  ./k8s-secrets/secrets/trackman/config-fm/config.json as Text
              , `service_account.json` =
                  ./k8s-secrets/secrets/trackman/config-fm/service_account.json as Text
              }
          )
      }

in  secret
