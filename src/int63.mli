(** This module extends {{!Base.Int63}[Base.Int63]}. *)

(** {2 Interface from Base} *)

(** @open *)
include
module type of struct
  include Base.Int63
end
  with module Hex := Base.Int63.Hex

(** {2 Extensions} *)

(** @open *)
include
  Int_intf.Extension_with_stable
  with type t := t
   and type comparator_witness := comparator_witness
