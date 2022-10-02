let app = ./lib/app.dhall

let config = ./lib/config.dhall

let env = ./lib/env.dhall

let services = ./lib/services.dhall

let storage = ./lib/storage.dhall

let typesUnion = ./lib/typesUnion.dhall

let util = ./lib/util.dhall

let volumes = ./lib/volumes.dhall

in  { app, config, env, services, storage, typesUnion, util, volumes }
