let Prelude = ../Prelude.dhall

let kubernetes = ../kubernetes.dhall

let HTTPLivenessProbe =
      { Type =
          { path : Text
          , initialDelaySeconds : Optional Natural
          , periodSeconds : Optional Natural
          , timeoutSeconds : Optional Natural
          , successThreshold : Optional Natural
          , failureThreshold : Optional Natural
          }
      , default =
        { initialDelaySeconds = None Natural
        , periodSeconds = None Natural
        , timeoutSeconds = None Natural
        , successThreshold = None Natural
        , failureThreshold = None Natural
        }
      }

let HTTPService =
      { Type =
          { port : Natural
          , targetPort : Optional Natural
          , livenessProbe : Optional HTTPLivenessProbe.Type
          }
      , default =
        { port = 80
        , targetPort = None Natural
        , livenessProbe = None HTTPLivenessProbe.Type
        }
      }

let TCPService =
      { Type =
          { name : Optional Text
          , port : Natural
          , targetPort : Optional Natural
          }
      , default = { name = None Text, targetPort = None Natural }
      }

let Service = < HTTPService : HTTPService.Type | TCPService : TCPService.Type >

let mkLivenessProbe
    : Service -> Optional kubernetes.Probe.Type
    = \(service : Service) ->
        merge
          { HTTPService =
              \(httpService : HTTPService.Type) ->
                Prelude.Optional.map
                  HTTPLivenessProbe.Type
                  kubernetes.Probe.Type
                  ( \(probe : HTTPLivenessProbe.Type) ->
                      kubernetes.Probe::{
                      , httpGet = Some kubernetes.HTTPGetAction::{
                        , path = Some probe.path
                        , port = kubernetes.NatOrString.Nat httpService.port
                        , scheme = Some "HTTP"
                        }
                      , initialDelaySeconds = probe.initialDelaySeconds
                      , periodSeconds = probe.periodSeconds
                      , timeoutSeconds = probe.timeoutSeconds
                      , successThreshold = probe.successThreshold
                      , failureThreshold = probe.failureThreshold
                      }
                  )
                  httpService.livenessProbe
          , TCPService =
              \(tcpService : TCPService.Type) -> None kubernetes.Probe.Type
          }
          service

let mkContainerPorts =
      \(service : Service) ->
        [ merge
            { HTTPService =
                \(httpService : HTTPService.Type) ->
                  kubernetes.ContainerPort::{
                  , containerPort =
                      Prelude.Optional.default
                        Natural
                        httpService.port
                        httpService.targetPort
                  }
            , TCPService =
                \(tcpService : TCPService.Type) ->
                  kubernetes.ContainerPort::{
                  , containerPort =
                      Prelude.Optional.default
                        Natural
                        tcpService.port
                        tcpService.targetPort
                  }
            }
            service
        ]

let mkServicePorts =
      \(service : Service) ->
        [ merge
            { HTTPService =
                \(httpService : HTTPService.Type) ->
                  kubernetes.ServicePort::{
                  , name = Some "http"
                  , protocol = Some "TCP"
                  , port = httpService.port
                  , targetPort =
                      Prelude.Optional.map
                        Natural
                        kubernetes.NatOrString
                        (\(port : Natural) -> kubernetes.NatOrString.Nat port)
                        httpService.targetPort
                  }
            , TCPService =
                \(tcpService : TCPService.Type) ->
                  kubernetes.ServicePort::{
                  , name = tcpService.name
                  , protocol = Some "TCP"
                  , port = tcpService.port
                  , targetPort =
                      Prelude.Optional.map
                        Natural
                        kubernetes.NatOrString
                        (\(port : Natural) -> kubernetes.NatOrString.Nat port)
                        tcpService.targetPort
                  }
            }
            service
        ]

in  { Service
    , HTTPService
    , HTTPLivenessProbe
    , TCPService
    , mkLivenessProbe
    , mkContainerPorts
    , mkServicePorts
    }
