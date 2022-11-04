let lib = ../lib.dhall

let objectStorage = ../rook/objectStorage.dhall

let configMap =
      lib.storage.ConfigMap::{
      , name = "config"
      , data = toMap
          { `linx-server.conf` =
              ''
                sitename = wuvtLinx
                siteurl = https://linx-new.apps.wuvt.vt.edu
                allowhotlink = true
                maxexpiry = 2592000
                force-random-filename = true
              ''
          }
      }

let bucket = lib.storage.Bucket::{ name = "bucket", store = objectStorage }

let service =
      lib.networking.Service::{
      , name = Some "http"
      , port = 8080
      , livenessProbe = Some lib.networking.HTTPLivenessProbe::{
        , path = "/"
        , initialDelaySeconds = Some 60
        , timeoutSeconds = Some 5
        , failureThreshold = Some 5
        }
      }

let ingress =
      lib.networking.Ingress::{
      , service
      , host = "linx-new.apps.wuvt.vt.edu"
      , authenticated = True
      , sizeLimit = Some "4g"
      }

let app =
      lib.app.App::{
      , name = "linx"
      , replicas = 2
      , containers =
        [ lib.app.Container::{
          , image = "andreimarcu/linx-server:latest"
          , args =
            [ "-s3-endpoint=http://\$(BUCKET_HOST).cluster.local:\$(BUCKET_PORT)/"
            , "-s3-region=us-east-1"
            , "-s3-bucket=\$(BUCKET_NAME)"
            , "-s3-force-path-style=true"
            , "-config=/data/linx-server.conf"
            ]
          , volumes =
            [ lib.storage.Volume::{
              , name = "linx-config"
              , mountPath = "/data/linx-server.conf"
              , subPath = Some "linx-server.conf"
              , readOnly = Some True
              , source =
                  lib.storage.VolumeSource.ConfigMap
                    lib.storage.ConfigMapSource::{ configMap }
              }
            ]
          , service = Some service
          , bucket = Some bucket
          }
        ]
      }

in  [ lib.mkService service app
    , lib.mkIngress ingress app
    , lib.mkObjectBucketClaim bucket app
    , lib.mkConfigMap configMap app
    , lib.mkDeployment app
    ]
