let kubernetes = ../kubernetes.dhall

let secret =
      kubernetes.Secret::{
      , metadata = kubernetes.ObjectMeta::{ name = Some "mediawiki-config" }
      , type = Some "Opaque"
      , stringData = Some
          ( toMap
              { `LocalSettings.php` =
                  ./k8s-secrets/secrets/mediawiki/LocalSettings.php as Text
              }
          )
      }

in  secret
