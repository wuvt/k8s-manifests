let kubernetes = ../kubernetes.dhall

let config =
      kubernetes.Secret::{
      , metadata = kubernetes.ObjectMeta::{ name = Some "opensmtpd-config" }
      , type = Some "Opaque"
      , stringData = Some
          ( toMap
              { `smtpd.conf` = ./opensmtpd/config/smtpd.conf as Text
              , mailname = ./opensmtpd/config/mailname as Text
              , aliases = ./opensmtpd/config/aliases as Text
              , sources = ./opensmtpd/config/sources as Text
              }
          )
      }

let tls =
      kubernetes.Secret::{
      , metadata = kubernetes.ObjectMeta::{ name = Some "opensmtpd-tls" }
      , type = Some "kubernetes.io/tls"
      , stringData = Some
          ( toMap
              { `tls.crt` = ./opensmtpd/tls/tls.crt as Text
              , `tls.key` = ./opensmtpd/tls/tls.key as Text
              }
          )
      }

in  [ config, tls ]
