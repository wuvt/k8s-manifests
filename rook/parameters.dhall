let namespace = "rook-ceph"

let blockPoolSize = 2

let blockPoolFailureDomain = "osd"

let blockStorageName = "rook-ceph-block"

in  { namespace, blockPoolSize, blockPoolFailureDomain, blockStorageName }
