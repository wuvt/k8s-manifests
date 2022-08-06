let Prelude = ../Prelude.dhall

let mapEmpty
    : forall (a : Type) ->
      forall (b : Type) ->
      (a -> b) ->
      List a ->
        Optional (List b)
    = \(a : Type) ->
      \(b : Type) ->
      \(f : a -> b) ->
      \(xs : List a) ->
        if    Prelude.List.null a xs
        then  None (List b)
        else  Some (Prelude.List.map a b f xs)

in  { mapEmpty }
