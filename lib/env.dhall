let kubernetes = ../kubernetes.dhall

let SecretSource =
      { Type = { secret : kubernetes.Secret.Type, key : Text }, default = {=} }

let VariableSource = < Value : Text | Secret : SecretSource.Type >

let Variable =
      { Type = { name : Text, source : VariableSource }, default = {=} }

let mkVariable
    : Variable.Type -> kubernetes.EnvVar.Type
    = \(variable : Variable.Type) ->
        merge
          { Value =
              \(value : Text) ->
                kubernetes.EnvVar::{ name = variable.name, value = Some value }
          , Secret =
              \(secret : SecretSource.Type) ->
                kubernetes.EnvVar::{
                , name = variable.name
                , valueFrom = Some kubernetes.EnvVarSource::{
                  , secretKeyRef = Some kubernetes.SecretKeySelector::{
                    , name = secret.secret.metadata.name
                    , key = secret.key
                    }
                  }
                }
          }
          variable.source

in  { Variable, mkVariable, VariableSource, SecretSource }
