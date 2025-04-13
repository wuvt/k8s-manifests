let lib = ../lib.dhall

let kubernetes = ../kubernetes.dhall

let service = lib.networking.Service::{ name = Some "http", port = 80 }

let ingress =
      lib.networking.Ingress::{
      , service
      , host = "files.apps.wuvt.vt.edu"
      , authenticated = True
      }

let app =
      lib.app.App::{
      , name = "fileserver"
      , replicas = 0
      , containers = [] : List lib.app.Container.Type
      }

let endpoint =
      kubernetes.EndpointSlice::{
      , metadata = kubernetes.ObjectMeta::{
        , name = Some "fileserver"
        , labels = Some
            ( toMap
                { `app.kubernetes.io/name` = "fileserver"
                , `kubernetes.io/service-name` = "fileserver"
                }
            )
        }
      , addressType = "IPv4"
      , ports = Some
        [ kubernetes.EndpointPort::{
          , name = Some "http"
          , protocol = Some "TCP"
          , port = Some 80
          }
        ]
      , endpoints = [ kubernetes.Endpoint::{ addresses = [ "10.23.16.10" ] } ]
      }

in  [ lib.mkIngress ingress app
    , lib.mkService service app
    , lib.typesUnion.Kubernetes (kubernetes.Resource.EndpointSlice endpoint)
    ]
