let app = ./lib/app.dhall

let storage = ./lib/storage.dhall

let typesUnion = ./lib/typesUnion.dhall

let util = ./lib/util.dhall

let volumes = ./lib/volumes.dhall

in  { app, storage, typesUnion, util, volumes }
