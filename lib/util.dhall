let Prelude = ../Prelude.dhall

let listOptional
    : forall (a : Type) -> List a -> Optional (List a)
    = \(a : Type) ->
      \(xs : List a) ->
        if Prelude.List.null a xs then None (List a) else Some xs

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

let mapDefault
    : forall (a : Type) -> forall (b : Type) -> (a -> b) -> b -> Optional a -> b
    = \(a : Type) ->
      \(b : Type) ->
      \(f : a -> b) ->
      \(d : b) ->
      \(o : Optional a) ->
        merge { Some = \(x : a) -> f x, None = d } o

let appendMaybe
    : Text -> Optional Text -> Text
    = \(a : Text) ->
      \(b : Optional Text) ->
        mapDefault Text Text (\(extra : Text) -> "${a}-${extra}") a b

in  { listOptional, mapEmpty, mapDefault, appendMaybe }