let kubernetes = ../kubernetes.dhall

let service =
      kubernetes.Service::{
      , metadata = kubernetes.ObjectMeta::{
        , name = Some "postgres"
        , labels = Some (toMap { `app.kubernetes.io/name` = "postgres" })
        }
      , spec = Some kubernetes.ServiceSpec::{
        , ports = Some
          [ kubernetes.ServicePort::{ protocol = Some "TCP", port = 5432 } ]
        }
      }

let endpoint =
      kubernetes.EndpointSlice::{
      , metadata = kubernetes.ObjectMeta::{
        , name = Some "postgres-1"
        , labels = Some
            ( toMap
                { `app.kubernetes.io/name` = "postgres"
                , `kubernetes.io/service-name` = "postgres"
                }
            )
        }
      , addressType = "IPv4"
      , ports = Some
        [ kubernetes.EndpointPort::{
          , name = Some ""
          , protocol = Some "TCP"
          , port = Some 5432
          }
        ]
      , endpoints =
        [ kubernetes.Endpoint::{
          , addresses = [ "192.168.0.246", "192.168.0.247", "192.168.0.248" ]
          }
        ]
      }

in  [ kubernetes.Resource.Service service
    , kubernetes.Resource.EndpointSlice endpoint
    ]
