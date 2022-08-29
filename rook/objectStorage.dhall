let storage = ../lib/storage.dhall

let store =
      storage.CephObjectStore::{
      , name = "objectstore"
      , storageName = "rook-ceph-bucket"
      , namespace = "rook-ceph"
      , failureDomain = "osd"
      , replicas = 2
      , gatewayInstances = 1
      , healthCheckInterval = "60s"
      }

let mkClaim = storage.mkObjectBucketClaim store

in  { store, mkClaim }
