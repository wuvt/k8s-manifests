let Prelude = ../Prelude.dhall

let kubernetes = ../kubernetes.dhall

let ServiceProtocol = < TCPService | UDPService >

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

let Service =
      { Type =
          { name : Optional Text
          , protocol : ServiceProtocol
          , port : Natural
          , targetPort : Optional Natural
          , livenessProbe : Optional HTTPLivenessProbe.Type
          }
      , default =
        { name = None Text
        , protocol = ServiceProtocol.TCPService
        , targetPort = None Natural
        , livenessProbe = None HTTPLivenessProbe.Type
        }
      }

let mkLivenessProbe
    : Service.Type -> Optional kubernetes.Probe.Type
    = \(service : Service.Type) ->
        Prelude.Optional.map
          HTTPLivenessProbe.Type
          kubernetes.Probe.Type
          ( \(probe : HTTPLivenessProbe.Type) ->
              kubernetes.Probe::{
              , httpGet = Some kubernetes.HTTPGetAction::{
                , path = Some probe.path
                , port = kubernetes.NatOrString.Nat service.port
                , scheme = Some "HTTP"
                }
              , initialDelaySeconds = probe.initialDelaySeconds
              , periodSeconds = probe.periodSeconds
              , timeoutSeconds = probe.timeoutSeconds
              , successThreshold = probe.successThreshold
              , failureThreshold = probe.failureThreshold
              }
          )
          service.livenessProbe

let mkContainerPorts =
      \(service : Service.Type) ->
        [ kubernetes.ContainerPort::{
          , containerPort =
              Prelude.Optional.default Natural service.port service.targetPort
          }
        ]

let mkServicePorts =
      \(service : Service.Type) ->
        [ kubernetes.ServicePort::{
          , name = service.name
          , protocol =
              merge
                { TCPService = Some "TCP", UDPService = Some "UDP" }
                service.protocol
          , port = service.port
          , targetPort =
              Prelude.Optional.map
                Natural
                kubernetes.NatOrString
                (\(port : Natural) -> kubernetes.NatOrString.Nat port)
                service.targetPort
          }
        ]

let Path = < Prefix : Text | Exact : Text >

let Ingress =
      { Type =
          { service : Service.Type
          , instance : Optional Text
          , host : Text
          , authenticated : Bool
          , sizeLimit : Optional Text
          , paths : List Path
          , pathRegex : Bool
          }
      , default =
        { instance = None Text
        , authenticated = False
        , sizeLimit = None Text
        , paths = [ Path.Prefix "/" ]
        , pathRegex = False
        }
      }

in  { Service
    , ServiceProtocol
    , HTTPLivenessProbe
    , mkLivenessProbe
    , mkContainerPorts
    , mkServicePorts
    , Ingress
    , Path
    }
