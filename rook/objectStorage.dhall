let storage = ../lib/storage.dhall

in  storage.CephObjectStore::{
    , name = "objectstore"
    , storageName = "rook-ceph-bucket"
    , namespace = "rook-ceph"
    , failureDomain = "osd"
    , replicas = 2
    , gatewayInstances = 1
    , healthCheckInterval = "60s"
    }
