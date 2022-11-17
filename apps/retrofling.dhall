let lib = ../lib.dhall

let service = lib.networking.Service::{ name = Some "http", port = 8080 }

let ingress =
      lib.networking.Ingress::{ service, host = "retrofling.apps.wuvt.vt.edu" }

let app =
      lib.app.App::{
      , name = "retrofling"
      , replicas = 2
      , containers =
        [ lib.app.Container::{
          , image = "ghcr.io/wuvt/retrofling:latest"
          , service = Some service
          }
        ]
      }

in  [ lib.mkService service app
    , lib.mkIngress ingress app
    , lib.mkDeployment app
    ]
