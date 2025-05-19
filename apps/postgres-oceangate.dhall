let kubernetes = ../kubernetes.dhall

let service =
      kubernetes.Service::{
      , metadata = kubernetes.ObjectMeta::{
        , name = Some "postgres-new"
        , labels = Some (toMap { `app.kubernetes.io/name` = "postgres-new" })
        }
      , spec = Some kubernetes.ServiceSpec::{
        , ports = Some
          [ kubernetes.ServicePort::{ protocol = Some "TCP", port = 5432 } ]
        }
      }

let endpoint =
      kubernetes.EndpointSlice::{
      , metadata = kubernetes.ObjectMeta::{
        , name = Some "postgres-new-1"
        , labels = Some
            ( toMap
                { `app.kubernetes.io/name` = "postgres-new"
                , `kubernetes.io/service-name` = "postgres-new"
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
          , addresses = [ "10.23.16.5" ]
          }
        ]
      }

in  [ kubernetes.Resource.Service service
    , kubernetes.Resource.EndpointSlice endpoint
    ]
