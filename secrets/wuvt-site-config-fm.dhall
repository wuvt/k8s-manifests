let kubernetes = ../kubernetes.dhall

let secret =
      kubernetes.Secret::{
      , metadata = kubernetes.ObjectMeta::{ name = Some "wuvt-site-config-fm" }
      , type = Some "Opaque"
      , stringData = Some
          ( toMap
              { `client_secrets.json` =
                  ./k8s-secrets/secrets/wuvt-site/config-fm/client_secrets.json as Text
              , `config.json` =
                  ./k8s-secrets/secrets/wuvt-site/config-fm/config.json as Text
              , `service_account.json` =
                  ./k8s-secrets/secrets/wuvt-site/config-fm/service_account.json as Text
              , `uwsgi.ini` =
                  ./k8s-secrets/secrets/wuvt-site/config-fm/uwsgi.ini as Text
              }
          )
      }

in  secret
