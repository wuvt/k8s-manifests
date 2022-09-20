let Prelude = ../Prelude.dhall

let kubernetes = ../kubernetes.dhall

let TCPService =
      { Type =
          { name : Optional Text
          , port : Natural
          , targetPort : Optional Natural
          }
      , default = { name = None Text, targetPort = None Natural }
      }

let Service = < TCPService : TCPService.Type >

let mkContainerPorts =
      \(service : Service) ->
        [ merge
            { TCPService =
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
            { TCPService =
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
    , TCPService
    , mkContainerPorts
    , mkServicePorts
    }
