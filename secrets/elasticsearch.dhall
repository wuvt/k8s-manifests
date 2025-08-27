let kubernetes = ../kubernetes.dhall

let secret =
      kubernetes.Secret::{
      , metadata = kubernetes.ObjectMeta::{
        , name = Some "elasticsearch-nginx-auth"
        }
      , type = Some "Opaque"
      , stringData = Some
          ( toMap
              { `elasticsearch.htpasswd` =
                  ./k8s-secrets/secrets/elasticsearch/elasticsearch.htpasswd as Text
              }
          )
      }

in  secret
