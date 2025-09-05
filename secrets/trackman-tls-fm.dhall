let kubernetes = ../kubernetes.dhall

let secret =
      kubernetes.Secret::{
      , metadata = kubernetes.ObjectMeta::{ name = Some "wuvt-site-tls-fm" }
      , type = Some "kubernetes.io/tls"
      , stringData = Some
          ( toMap
              { `tls.crt` =
                  ./k8s-secrets/secrets/trackman/tls-fm/tls.crt as Text
              , `tls.key` =
                  ./k8s-secrets/secrets/trackman/tls-fm/tls.key as Text
              }
          )
      }

in  secret
