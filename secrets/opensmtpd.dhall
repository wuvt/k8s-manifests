let kubernetes = ../kubernetes.dhall

let config =
      kubernetes.Secret::{
      , metadata = kubernetes.ObjectMeta::{ name = Some "opensmtpd-config" }
      , type = Some "Opaque"
      , stringData = Some
          ( toMap
              { `smtpd.conf` = ./k8s-secrets/secrets/opensmtpd/config/smtpd.conf as Text
              , mailname = ./k8s-secrets/secrets/opensmtpd/config/mailname as Text
              , aliases = ./k8s-secrets/secrets/opensmtpd/config/aliases as Text
              , sources = ./k8s-secrets/secrets/opensmtpd/config/sources as Text
              }
          )
      }

let tls =
      kubernetes.Secret::{
      , metadata = kubernetes.ObjectMeta::{ name = Some "opensmtpd-tls" }
      , type = Some "kubernetes.io/tls"
      , stringData = Some
          ( toMap
              { `tls.crt` = ./k8s-secrets/secrets/opensmtpd/tls/tls.crt as Text
              , `tls.key` = ./k8s-secrets/secrets/opensmtpd/tls/tls.key as Text
              }
          )
      }

in  [ config, tls ]
