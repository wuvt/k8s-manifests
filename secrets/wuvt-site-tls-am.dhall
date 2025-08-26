let kubernetes = ../kubernetes.dhall

let secret =
      kubernetes.Secret::{
      , metadata = kubernetes.ObjectMeta::{ name = Some "wuvt-site-tls-am" }
      , type = Some "kubernetes.io/tls"
      , stringData = Some
          ( toMap
              { `tls.crt` =
                  ./k8s-secrets/secrets/wuvt-site/tls-am/tls.crt as Text
              , `tls.key` =
                  ./k8s-secrets/secrets/wuvt-site/tls-am/tls.key as Text
              }
          )
      }

in  secret
