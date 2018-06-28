open! Import

(* These two are needed because [include Identifiable.Extend] (present later in the file)
   binds new [Map] and [Set] modules. *)
module Core_map = Map
module Core_set = Set

module Stable = struct
  module V1 = struct
    module T = struct
      type t = string [@@deriving bin_io]
      include (Base.String : module type of struct include Base.String end
               with type t := t)
    end
    include T
    include Comparable.Stable.V1.Make (T)
  end
end

module Caseless = struct
  module T = struct
    type t = string [@@deriving bin_io]
    include (Base.String.Caseless : module type of struct include Base.String.Caseless end
             with type t := t)
  end
  include T
  include Comparable.Make_binable_using_comparator(T)
  include Hashable.Make_binable(T)
end

type t = string [@@deriving typerep]

include (Base.String
         : module type of struct include Base.String end
         with type t := t
         with module Caseless := Base.String.Caseless)

include Identifiable.Extend (Base.String) (struct
    type t = string [@@deriving bin_io]
  end)

include Hexdump.Of_indexable (struct
    type t = string
    let length = length
    let get    = get
  end)

let gen = Base_quickcheck.Generator.string
let obs = Base_quickcheck.Observer.string
let shrinker = Base_quickcheck.Shrinker.string

let gen_nonempty = Base_quickcheck.Generator.string_non_empty
let gen' = Base_quickcheck.Generator.string_of
let gen_nonempty' = Base_quickcheck.Generator.string_non_empty_of

let gen_with_length length chars =
  Base_quickcheck.Generator.string_with_length_of chars ~length

let take_while t ~f =
  match lfindi t ~f:(fun _ elt -> not (f elt)) with
  | None -> t
  | Some i -> sub t ~pos:0 ~len:i
;;

let rtake_while t ~f =
  match rfindi t ~f:(fun _ elt -> not (f elt)) with
  | None -> t
  | Some i -> sub t ~pos:(i + 1) ~len:(length t - i - 1)
;;

(** See {!Array.normalize} for the following 4 functions. *)
let normalize t i =
  Ordered_collection_common.normalize ~length_fun:length t i

let slice t start stop =
  Ordered_collection_common.slice ~length_fun:length ~sub_fun:sub
    t start stop

let nget x i =
  let module String = Base.String in
  x.[normalize x i]
