let Prelude = ./Prelude.dhall

let kubernetes = ./kubernetes.dhall

let rook = ./rook.dhall

let app = ./lib/app.dhall

let networking = ./lib/networking.dhall

let storage = ./lib/storage.dhall

let typesUnion = ./lib/typesUnion.dhall

let util = ./lib/util.dhall

let blockStorage = ./rook/blockStorage.dhall

let objectStorage = ./rook/objectStorage.dhall

let mkDeployment
    : app.App.Type -> typesUnion
    = \(app : app.App.Type) ->
        let deployment =
              kubernetes.Deployment::{
              , metadata = kubernetes.ObjectMeta::{
                , name = Some (app@1.mkFullName app)
                , labels = Some (app@1.mkLabels app)
                }
              , spec = Some kubernetes.DeploymentSpec::{
                , replicas = Some app.replicas
                , selector = kubernetes.LabelSelector::{
                  , matchLabels = Some (app@1.mkLabels app)
                  }
                , template = kubernetes.PodTemplateSpec::{
                  , metadata = Some kubernetes.ObjectMeta::{
                    , labels = Some (app@1.mkLabels app)
                    }
                  , spec = Some kubernetes.PodSpec::{
                    , containers =
                        Prelude.List.map
                          app@1.Container.Type
                          kubernetes.Container.Type
                          (app@1.mkContainer (app@1.mkFullName app))
                          app.containers
                    , volumes =
                        util.mapEmpty
                          storage.Volume.Type
                          kubernetes.Volume.Type
                          (storage.mkVolumeSource (app@1.mkFullName app))
                          ( Prelude.List.concatMap
                              app@1.Container.Type
                              storage.Volume.Type
                              ( \(container : app@1.Container.Type) ->
                                  container.volumes
                              )
                              app.containers
                          )
                    , nodeName = app.nodeName
                    , securityContext =
                        Prelude.Optional.map
                          Natural
                          kubernetes.PodSecurityContext.Type
                          ( \(user : Natural) ->
                              kubernetes.PodSecurityContext::{
                              , runAsUser = Some user
                              , runAsGroup = Some user
                              , fsGroup = Some user
                              }
                          )
                          app.user
                    }
                  }
                }
              }

        in  typesUnion.Kubernetes (kubernetes.Resource.Deployment deployment)

let mkService
    : networking.Service.Type -> app.App.Type -> typesUnion
    = \(service : networking.Service.Type) ->
      \(app : app.App.Type) ->
        let service =
              kubernetes.Service::{
              , metadata = kubernetes.ObjectMeta::{
                , name = Some (app@1.mkFullName app)
                , labels = Some (app@1.mkLabels app)
                }
              , spec = Some kubernetes.ServiceSpec::{
                , selector = Some (app@1.mkLabels app)
                , ports = Some (networking.mkServicePorts service)
                }
              }

        in  typesUnion.Kubernetes (kubernetes.Resource.Service service)

let mkIngress
    : networking.Ingress.Type -> app.App.Type -> typesUnion
    = \(ingress : networking.Ingress.Type) ->
      \(app : app.App.Type) ->
        let ingressResource =
              kubernetes.Ingress::{
              , metadata = kubernetes.ObjectMeta::{
                , name = Some
                    (util.appendMaybe (app@1.mkFullName app) ingress.instance)
                , labels = Some (app@1.mkLabels app)
                , annotations =
                    util.listOptional
                      (Prelude.Map.Entry Text Text)
                      (   ( if    ingress.authenticated
                            then  toMap
                                    { `nginx.ingress.kubernetes.io/auth-url` =
                                        "http://oauth2-proxy.default.svc.cluster.local:4180/oauth2/auth"
                                    , `nginx.ingress.kubernetes.io/auth-signin` =
                                        "https://login.apps.wuvt.vt.edu/oauth2/start?rd=\$scheme%3A%2F%2F\$host\$escaped_request_uri"
                                    }
                            else  Prelude.Map.empty Text Text
                          )
                        # util.mapDefault
                            Text
                            (Prelude.Map.Type Text Text)
                            ( \(limit : Text) ->
                                toMap
                                  { `nginx.ingress.kubernetes.io/proxy-body-size` =
                                      limit
                                  }
                            )
                            (Prelude.Map.empty Text Text)
                            ingress.sizeLimit
                        # ( if    ingress.pathRegex
                            then  toMap
                                    { `nginx.ingress.kubernetes.io/use-regex` =
                                        "true"
                                    }
                            else  Prelude.Map.empty Text Text
                          )
                      )
                }
              , spec = Some kubernetes.IngressSpec::{
                , rules = Some
                  [ kubernetes.IngressRule::{
                    , host = Some ingress.host
                    , http = Some kubernetes.HTTPIngressRuleValue::{
                      , paths =
                          Prelude.List.map
                            networking.Path
                            kubernetes.HTTPIngressPath.Type
                            ( \(path : networking.Path) ->
                                let backend =
                                      kubernetes.IngressBackend::{
                                      , service = Some kubernetes.IngressServiceBackend::{
                                        , name = app@1.mkFullName app
                                        , port = Some kubernetes.ServiceBackendPort::{
                                          , number = Some ingress.service.port
                                          }
                                        }
                                      }

                                in  merge
                                      { Prefix =
                                          \(path : Text) ->
                                            kubernetes.HTTPIngressPath::{
                                            , path = Some path
                                            , pathType = "Prefix"
                                            , backend
                                            }
                                      , Exact =
                                          \(path : Text) ->
                                            kubernetes.HTTPIngressPath::{
                                            , path = Some path
                                            , pathType = "Exact"
                                            , backend
                                            }
                                      }
                                      path
                            )
                            ingress.paths
                      }
                    }
                  ]
                }
              }

        in  typesUnion.Kubernetes (kubernetes.Resource.Ingress ingressResource)

let mkBlockStorageClaim
    : storage.Block.Type -> app.App.Type -> typesUnion
    = \(block : storage.Block.Type) ->
      \(app : app.App.Type) ->
        let claim =
              kubernetes.PersistentVolumeClaim::{
              , metadata = kubernetes.ObjectMeta::{
                , name = Some "${app@1.mkFullName app}-${block.name}"
                , labels = Some (app@1.mkLabels app)
                }
              , spec = Some kubernetes.PersistentVolumeClaimSpec::{
                , storageClassName = Some
                    ( Prelude.Optional.default
                        storage.CephBlockPool.Type
                        blockStorage
                        block.store
                    ).storageName
                , accessModes = Some block.accessModes
                , resources = Some kubernetes.ResourceRequirements::{
                  , requests = Some (toMap { storage = block.size })
                  }
                }
              }

        in  typesUnion.Kubernetes
              (kubernetes.Resource.PersistentVolumeClaim claim)

let mkObjectBucketClaim
    : storage.Bucket.Type -> app.App.Type -> typesUnion
    = \(bucket : storage.Bucket.Type) ->
      \(app : app.App.Type) ->
        let claim =
              rook.ObjectBucketClaim::{
              , metadata = kubernetes.ObjectMeta::{
                , name = Some "${app@1.mkFullName app}-${bucket.name}"
                , labels = Some (app@1.mkLabels app)
                }
              , spec = Some rook.ObjectBucketClaimSpec::{
                , storageClassName =
                    ( Prelude.Optional.default
                        storage.CephObjectStore.Type
                        objectStorage
                        bucket.store
                    ).storageName
                , generateBucketName = Some
                    "${app@1.mkFullName app}-${bucket.name}"
                }
              }

        in  typesUnion.Rook (rook.Resource.ObjectBucketClaim claim)

let mkConfigMap
    : storage.ConfigMap.Type -> app.App.Type -> typesUnion
    = \(config : storage.ConfigMap.Type) ->
      \(app : app.App.Type) ->
        let configMap =
              kubernetes.ConfigMap::{
              , metadata = kubernetes.ObjectMeta::{
                , name = Some "${app@1.mkFullName app}-${config.name}"
                , labels = Some (app@1.mkLabels app)
                }
              , data = Some config.data
              }

        in  typesUnion.Kubernetes (kubernetes.Resource.ConfigMap configMap)

in  { app
    , networking
    , storage
    , typesUnion
    , util
    , mkDeployment
    , mkService
    , mkIngress
    , mkBlockStorageClaim
    , mkObjectBucketClaim
    , mkConfigMap
    }
