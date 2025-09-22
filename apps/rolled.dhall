let lib = ../lib.dhall

let service = lib.networking.Service::{ name = Some "http", port = 80 }

let ingress =
      lib.networking.Ingress::{
      , service
      , host = "rolled.apps.wuvt.vt.edu"
      , authenticated = True
      }

let app =
      lib.app.App::{
      , name = "rolled"
      , replicas = 1
      , containers =
        [ lib.app.Container::{
          , image = "ghcr.io/wuvt/rolled-frontend:frontend-v1.1.0"
          , service = Some service
          , env =
            [ lib.app.Variable::{
              , name = "FE_TYPESENSE_HOST"
              , source =
                  lib.app.VariableSource.Value
                    "typesense.apps.wuvt.vt.edu"
              }
            , lib.app.Variable::{
              , name = "FE_TYPESENSE_PORT"
              , source = lib.app.VariableSource.Value "443"
              }
            , lib.app.Variable::{
              , name = "FE_TYPESENSE_PROTO"
              , source = lib.app.VariableSource.Value "https"
              }
            , lib.app.Variable::{
              , name = "FE_TYPESENSE_SEARCHKEY"
              , source = lib.app.VariableSource.Value "goodbyeenvygoodbyesorrowyouwerelegendary"
              }
            , lib.app.Variable::{ {- this does practically nothing -}
              , name = "FE_ALLOWED"
              , source = lib.app.VariableSource.Value "192.168.0.0/24 10.0.0.0/8 172.16.0.0/12 fd00::/8"
              }
            ]
          }
        ]
      }

in  [ lib.mkService service app
    , lib.mkIngress ingress app
    , lib.mkDeployment app
    ]
