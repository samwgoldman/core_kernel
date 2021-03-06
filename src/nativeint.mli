(** This module extends {{!Base.Nativeint}[Base.Nativeint]}. *)

(** @open *)
include
module type of struct
  include Base.Nativeint
end
  with module Hex := Base.Nativeint.Hex

include
  Int_intf.Extension with type t := t and type comparator_witness := comparator_witness
