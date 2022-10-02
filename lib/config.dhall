let Prelude = ../Prelude.dhall

let kubernetes = ../kubernetes.dhall

let typesUnion = ./typesUnion.dhall

let ConfigMap =
      { Type =
          { name : Text
          , appName : Optional Text
          , data : List { mapKey : Text, mapValue : Text }
          }
      , default =
        { appName = None Text
        , data = [] : List { mapKey : Text, mapValue : Text }
        }
      }

let mkConfigMap
    : ConfigMap.Type -> typesUnion
    = \(config : ConfigMap.Type) ->
        let configMap =
              kubernetes.ConfigMap::{
              , metadata = kubernetes.ObjectMeta::{
                , name = Some config.name
                , labels =
                    Prelude.Optional.map
                      Text
                      (Prelude.Map.Type Text Text)
                      ( \(name : Text) ->
                          toMap { `app.kubernetes.io/name` = name }
                      )
                      config.appName
                }
              , data = Some config.data
              }

        in  typesUnion.Kubernetes (kubernetes.Resource.ConfigMap configMap)

in  { ConfigMap, mkConfigMap }
