let storage = ../lib/storage.dhall

let pool =
      storage.CephBlockPool::{
      , name = "replicapool"
      , storageName = "rook-ceph-block"
      , namespace = "rook-ceph"
      , failureDomain = "osd"
      , replicas = 2
      }

let mkClaim = storage.mkBlockStorageClaim pool

in  { pool, mkClaim }
