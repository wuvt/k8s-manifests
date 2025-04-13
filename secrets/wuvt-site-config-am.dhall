let kubernetes = ../kubernetes.dhall

let secret =
      kubernetes.Secret::{
      , metadata = kubernetes.ObjectMeta::{ name = Some "wuvt-site-config-am" }
      , type = Some "Opaque"
      , stringData = Some
          ( toMap
              { `client_secrets.json` =
                  ./k8s-secrets/secrets/wuvt-site/config-am/client_secrets.json as Text
              , `config.json` =
                  ./k8s-secrets/secrets/wuvt-site/config-am/config.json as Text
              , `service_account.json` =
                  ./k8s-secrets/secrets/wuvt-site/config-am/service_account.json as Text
              , `uwsgi.ini` =
                  ./k8s-secrets/secrets/wuvt-site/config-am/uwsgi.ini as Text
              }
          )
      }

in  secret
