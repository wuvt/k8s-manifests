let rook =
      https://raw.githubusercontent.com/jbellerb/dhall-rook/e3d3e58a0a13fa2dcb4149fcfc9700f5634f28b0/1.9/package.dhall
        sha256:35f3b0445607eb9041f5c672b5491680773d79df3127e8513850bc7b46c017aa

in  rook
      ( https://raw.githubusercontent.com/dhall-lang/dhall-kubernetes/753c7d04fb70845294095abb350cdadc79a94184/1.23/types.dhall
          sha256:ca91df3b01e6260b3262f9e17f5efa1c8ac26576c5c3cc9f58fa20e46a84c8b2
      ).(https://raw.githubusercontent.com/jbellerb/dhall-rook/e3d3e58a0a13fa2dcb4149fcfc9700f5634f28b0/1.9/kubernetes.dhall
           sha256:f0ef70ac1dba3d960b877accd30d1fb79019f1627fbdb356a84f31ed385f3e21)
