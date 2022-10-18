let Prelude = ../Prelude.dhall

let kubernetes = ../kubernetes.dhall

let app = ./app.dhall

let services = ./services.dhall

let typesUnion = ./typesUnion.dhall

let Ingress =
      { Type = { service : services.Service.Type, host : Text }, default = {=} }

let mkIngress
    : Ingress.Type -> app.App.Type -> typesUnion
    = \(ingress : Ingress.Type) ->
      \(app : app.App.Type) ->
        let ingressResource =
              kubernetes.Ingress::{
              , metadata = kubernetes.ObjectMeta::{
                , name = Some (app@1.mkFullName app)
                , labels = Some (app@1.mkLabels app)
                }
              , spec = Some kubernetes.IngressSpec::{
                , rules = Some
                  [ kubernetes.IngressRule::{
                    , host = Some ingress.host
                    , http = Some kubernetes.HTTPIngressRuleValue::{
                      , paths =
                        [ kubernetes.HTTPIngressPath::{
                          , path = Some "/"
                          , pathType = "Prefix"
                          , backend = kubernetes.IngressBackend::{
                            , service = Some kubernetes.IngressServiceBackend::{
                              , name = app@1.mkFullName app
                              , port = Some kubernetes.ServiceBackendPort::{
                                , number = Some ingress.service.port
                                }
                              }
                            }
                          }
                        ]
                      }
                    }
                  ]
                }
              }

        in  typesUnion.Kubernetes (kubernetes.Resource.Ingress ingressResource)

in  { Ingress, mkIngress }
