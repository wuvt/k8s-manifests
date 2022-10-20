let lib = ../lib.dhall

let objectStorage = ../rook/objectStorage.dhall

let configMap =
      lib.config.ConfigMap::{
      , name = "linx-config"
      , appName = Some "linx"
      , data = toMap
          { `linx-server.conf` =
              ''
                sitename = wuvtLinx
                siteurl = https://linx.apps.wuvt.vt.edu/
                allowhotlink = true
                maxexpiry = 2592000
                force-random-filename = true
              ''
          }
      }

let bucket =
      lib.storage.Bucket::{
      , name = "linx-bucket"
      , store = objectStorage
      , appName = Some "linx"
      }

let service =
      lib.services.Service::{
      , name = Some "http"
      , port = 8080
      , livenessProbe = Some lib.services.HTTPLivenessProbe::{
        , path = "/"
        , initialDelaySeconds = Some 60
        , timeoutSeconds = Some 5
        , failureThreshold = Some 5
        }
      }

let ingress = lib.ingress.Ingress::{ service, host = "linx.apps.wuvt.vt.edu" }

let app =
      lib.app.App::{
      , name = "linx"
      , replicas = 2
      , containers =
        [ lib.app.Container::{
          , image = "andreimarcu/linx-server:latest"
          , args =
            [ "-s3-endpoint=https://\$(BUCKET_HOST):\$(BUCKET_PORT)/"
            , "-s3-bucket=\$(BUCKET_NAME)"
            , "-config=/data/linx-server.conf"
            ]
          , volumes =
            [ lib.volumes.Volume::{
              , name = "linx-config"
              , mountPath = "/data/linx-server.conf"
              , subPath = Some "linx-server.conf"
              , readOnly = Some True
              , source =
                  lib.volumes.VolumeSource.ConfigMap
                    lib.volumes.ConfigMapSource::{ configMap }
              }
            ]
          , service = Some service
          , bucket = Some bucket
          }
        ]
      }

in  [ lib.app.mkService service app
    , lib.ingress.mkIngress ingress app
    , lib.storage.mkObjectBucketClaim bucket
    , lib.config.mkConfigMap configMap
    , lib.app.mkDeployment app
    ]
