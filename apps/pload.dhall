let lib = ../lib.dhall

let ploadSecret = ../secrets/pload-fm.dhall

let ploadService =
      lib.networking.Service::{
      , name = Some "http"
      , port = 8080
      , targetPort = Some 5000
      }

let ploadIngress =
      lib.networking.Ingress::{
      , service = ploadService
      , host = "new-playlists-fm.apps.wuvt.vt.edu"
      , authenticated = True
      }

let pload =
      lib.app.App::{
      , name = "pload"
      , instance = Some "fm"
      , replicas = 1
      , containers =
        [ lib.app.Container::{
          , name = Some "pload"
          , image = "ghcr.io/wuvt/pload:latest"
          , volumes =
            [ lib.storage.Volume::{
              , name = "pload-fm-config"
              , mountPath = "/data/config"
              , readOnly = Some True
              , source =
                  lib.storage.VolumeSource.Secret
                    lib.storage.SecretSource::{ secret = ploadSecret }
              }
            , lib.storage.Volume::{
              , name = "tzinfo"
              , mountPath = "/etc/localtime"
              , source =
                  lib.storage.VolumeSource.Host
                    lib.storage.HostSource::{
                    , path = "/usr/share/zoneinfo/America/New_York"
                    }
              }
            ]
          , env =
            [ lib.app.Variable::{
              , name = "APP_CONFIG_PATH"
              , source = lib.app.VariableSource.Value "/data/config/config.json"
              }
            ]
          }
        ]
      }

let elasticsearchSecret = ../secrets/elasticsearch.dhall

let elasticsearchService =
      lib.networking.Service::{
      , name = Some "http"
      , port = 9200
      , targetPort = Some 80
      }

let elasticsearchBlock =
      lib.storage.Block::{ name = "elasticsearch-db", size = "5Gi" }

let elasticsearch =
      lib.app.App::{
      , name = "elasticsearch"
      , replicas = 1
      , containers =
        [ lib.app.Container::{
          , name = Some "elasticsearch"
          , image = "elasticsearch:7.16.1"
          , volumes =
            [ lib.storage.Volume::{
              , name = "elasticsearch-data"
              , mountPath = "/usr/share/elasticsearch/data"
              , source =
                  lib.storage.VolumeSource.BlockStorage
                    lib.storage.BlockStorageSource::{
                    , block = elasticsearchBlock
                    }
              }
            ]
          , extraCapabilites = [ "SYS_CHROOT" ]
          , env =
            [ lib.app.Variable::{
              , name = "cluster.name"
              , source = lib.app.VariableSource.Value "wuvt"
              }
            , lib.app.Variable::{
              , name = "discovery.type"
              , source = lib.app.VariableSource.Value "single-node"
              }
            , lib.app.Variable::{
              , name = "ES_JAVA_OPTS"
              , source = lib.app.VariableSource.Value "-Xms4G -Xmx4G"
              }
            , lib.app.Variable::{
              , name = "xpack.ml.enabled"
              , source = lib.app.VariableSource.Value "false"
              }
            ]
          }
        , lib.app.Container::{
          , name = Some "elasticsearch-nginx"
          , image = "wuvt/nginx-elasticsearch:latest"
          , volumes =
            [ lib.storage.Volume::{
              , name = "elasticsearch-nginx-auth"
              , mountPath = "/etc/nginx/auth"
              , source =
                  lib.storage.VolumeSource.Secret
                    lib.storage.SecretSource::{ secret = elasticsearchSecret }
              }
            ]
          }
        ]
      }

in  [ lib.mkService ploadService pload
    , lib.mkIngress ploadIngress pload
    , lib.mkDeployment pload
    , lib.mkService elasticsearchService elasticsearch
    , lib.mkBlockStorageClaim elasticsearchBlock elasticsearch
    , lib.mkDeployment elasticsearch
    ]
