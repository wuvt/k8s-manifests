let storage = (../lib.dhall).storage

in  storage.CephBlockPool::{
    , name = "blockpool"
    , storageName = "rook-ceph-block"
    , namespace = "rook-ceph"
    , failureDomain = "osd"
    , replicas = 2
    }
