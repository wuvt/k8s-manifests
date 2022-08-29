let kubernetes = ../kubernetes.dhall

let rook = ../rook.dhall

in  < Kubernetes : kubernetes.Resource | Rook : rook.Resource >
