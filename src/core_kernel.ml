open! Import

(* holds modules that need to be exported, but that shouldn't generally be used.  Needs to
   be declared first because it uses names that are later shadowed. *)

module Std = struct
  include Std_kernel
  include Std_common

  module Container_intf                  = Container_intf
  module Core_hashtbl_intf               = Core_hashtbl_intf
  module Core_map_intf                   = Core_map_intf
  module Core_set_intf                   = Core_set_intf
  module Int_replace_polymorphic_compare = Int_replace_polymorphic_compare
  module Obj_array                       = Obj_array
  module Polymorphic_compare_intf        = Polymorphic_compare_intf
  module Stack_intf                      = Stack_intf
  module Timing_wheel_ns_intf            = Timing_wheel_ns_intf
end

include Std
module Stable = Stable

(** To be used in implementing Core, but not by end users *)
module Core_kernel_private = struct
  module Digit_string_helpers = Digit_string_helpers
  module Time0_intf           = Time0_intf
  module Time_intf            = Time_intf
  module Time_float0          = Time_float0
  module Kernel_time          = Time
  module Time_float           = Time_float
end

module Bigbuffer_internal              = Bigbuffer_internal
module Container_unit_tests            = Container_unit_tests
module Ofday                           = Ofday
module Perms                           = Perms
module Span                            = Span
module Stable_containers               = Stable_containers
module Stable_internal                 = Stable_internal
module Std_internal                    = Std_internal
module Std_kernel                      = Std_kernel
module Time_ns_alternate_sexp          = Time_ns_alternate_sexp
