let Prelude = ../Prelude.dhall

let lib = ../lib.dhall

let kubernetes = ../kubernetes.dhall

let secrets = ../secrets/opensmtpd.dhall

let SecretInfo = { name : Text, mountPath : Text }

let ZippedSecret = { _1 : SecretInfo, _2 : kubernetes.Secret.Type }

let secretList =
      Prelude.List.zip
        SecretInfo
        [ { name = "opensmtpd-config", mountPath = "/etc/smtpd" }
        , { name = "opensmtpd-tls", mountPath = "/etc/ssl/smtpd" }
        ]
        kubernetes.Secret.Type
        secrets

let service =
      lib.networking.Service::{ name = Some "smtp", open = True, port = 25 }

let app =
      lib.app.App::{
      , name = "opensmtpd"
      , replicas = 2
      , containers =
        [ lib.app.Container::{
          , image = "ghcr.io/wuvt/opensmtpd:latest"
          , volumes =
              Prelude.List.map
                ZippedSecret
                lib.storage.Volume.Type
                ( \(secret : ZippedSecret) ->
                    lib.storage.Volume::{
                    , name = secret._1.name
                    , mountPath = secret._1.mountPath
                    , readOnly = Some True
                    , source =
                        lib.storage.VolumeSource.Secret
                          lib.storage.SecretSource::{
                          , secret = secret._2
                          , mode = Some 256
                          }
                    }
                )
                secretList
          , extraCapabilites = [ "SYS_CHROOT" ]
          , service = Some service
          }
        ]
      }

in  [ lib.mkService service app, lib.mkDeployment app ]
