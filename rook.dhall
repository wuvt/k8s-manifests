let rook =
      https://raw.githubusercontent.com/jbellerb/dhall-rook/5f5e7fb7a6a8eeba1a0c53b32c112ce01486882a/1.9/package.dhall
        sha256:8a05f3f057948f6d95322899fb7cd60bf29a1fd0c98192069307ab8881b0dc74

in  rook
      ( https://raw.githubusercontent.com/dhall-lang/dhall-kubernetes/ece5035457eae0b60f63ea51a4e65db7e303a02b/1.22/types.dhall
          sha256:01165ec2044e8e3bc50f9ab9584957ab3a3d99d5c55180324334278bee13578e
      ).(https://raw.githubusercontent.com/jbellerb/dhall-rook/5f5e7fb7a6a8eeba1a0c53b32c112ce01486882a/1.9/kubernetes.dhall
           sha256:93084178b39aee10d65c4dc2a6dccc947a25f254239b1bf5f2d49974f6d10ca8)
