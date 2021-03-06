open! Import
open Std_internal

module type Span = sig
  (** [t] is immediate on 64bit boxes and so plays nicely with the GC write barrier. *)
  type t = private Int63.t [@@deriving hash]

  include Span_intf.S with type underlying = Int63.t and type t := t

  val of_sec_with_microsecond_precision : float -> t
  val of_int_us : int -> t
  val of_int_ms : int -> t
  val to_int_us : t -> int
  val to_int_ms : t -> int
  val to_int_sec : t -> int

  (** Contrary to the names, one can easily construct a [t] that is less than [min_value]
      or greater than [max_value].

      For [t]s that happen to be within these bounds, conversion to and from [Time.Span]
      rounds to the nearest microsecond.  This property supports {!Timing_wheel_float} in
      particular. *)
  val min_value : t

  val max_value : t

  (** overflows silently *)
  val scale_int : t -> int -> t

  (** overflows silently *)
  val scale_int63 : t -> Int63.t -> t

  (** Rounds down, and raises unless denominator is positive. *)
  val div : t -> t -> Int63.t

  (** Fast, implemented as the identity function. *)
  val to_int63_ns : t -> Int63.t

  (** Fast, implemented as the identity function. *)
  val of_int63_ns : Int63.t -> t

  (** Will raise on 32-bit platforms.  Consider [to_int63_ns] instead. *)
  val to_int_ns : t -> int

  val of_int_ns : int -> t
  val since_unix_epoch : unit -> t
  val random : ?state:Random.State.t -> unit -> t

  (** {!Time.t} is precise to approximately 0.24us in 2014.  If [to_span] converts to the
      closest [Time.Span.t], we have stability problems: converting back yields a
      different [t], sometimes different enough to have a different external
      representation, because the conversion back and forth crosses a rounding boundary.

      To stabilize conversion, we treat [Time.t] as having 1us precision: [to_span] and
      [of_span] both round to the nearest 1us.

      Around 135y magnitudes, [Time.Span.t] no longer has 1us resolution.  At that point,
      [to_span] and [of_span] raise.
  *)
  val to_span : t -> Span_float.t

  val of_span : Span_float.t -> t

  (** Note that we expose a sexp format that is not the one exposed in [Core]. *)
  module Alternate_sexp : sig
    type nonrec t = t [@@deriving sexp]
  end
  [@@deprecated "[since 2018-04] use [Span.sexp_of_t] and [Span.t_of_sexp] instead"]

  (*_ See the Jane Street Style Guide for an explanation of [Private] submodules:

    https://opensource.janestreet.com/standards/#private-submodules *)
  module Private : sig
    val check_range : t -> t
    val of_parts : Parts.t -> t
    val to_parts : t -> Parts.t
  end
end

module type Ofday = sig
  module Span : Span

  (** [t] is immediate on 64bit boxes and so plays nicely with the GC write barrier. *)
  type t = private Int63.t

  (** String and sexp output takes the form 'HH:MM:SS.sssssssss'; see
      {!Core_kernel.Ofday_intf} for accepted input. If input includes more than 9 decimal
      places in seconds, rounds to the nearest nanosecond, with the midpoint rounded up.
      Allows 60[.sss...] seconds for leap seconds but treats it as exactly 60s regardless
      of fractional part. *)
  include
    Ofday_intf.S with type underlying = Int63.t and type t := t and module Span := Span

  (** The largest representable value below [start_of_next_day], i.e. one nanosecond
      before midnight. *)
  val approximate_end_of_day : t
  (*_ This is already exported from [Ofday_intf.S], but we re-declare it to add
    documentation. *)

  (** [add_exn t span] shifts the time of day [t] by [span]. It raises if the result is
      not in the same 24-hour day. Daylight savings shifts are not accounted for. *)
  val add_exn : t -> Span.t -> t

  (** [sub_exn t span] shifts the time of day [t] back by [span]. It raises if the result
      is not in the same 24-hour day. Daylight savings shifts are not accounted for. *)
  val sub_exn : t -> Span.t -> t
end

(** Time represented as an [Int63.t] number of nanoseconds since the epoch.

    See {!Core.Time_ns} for important user documentation.

    Internally, arithmetic is not overflow-checked.  Instead, overflows are silently
    ignored, as for [int] arithmetic.  Conversions may (or may not) raise if prior
    arithmetic operations overflowed. *)
module type Time_ns = sig
  module Span : Span
  module Ofday : Ofday with module Span := Span

  type t = private Int63.t [@@deriving hash, typerep, bin_io]

  include Comparisons.S with type t := t

  (** Note that we expose a sexp format that is not the one exposed in [Core]. *)
  module Alternate_sexp : sig
    type nonrec t = t [@@deriving sexp]
  end

  include
    Time_intf.Shared with type t := t with module Span := Span with module Ofday := Ofday

  (** Unix epoch (1970-01-01 00:00:00 UTC) *)
  val epoch : t

  val min_value : t
  val max_value : t
  val now : unit -> t

  (** overflows silently *)
  val add : t -> Span.t -> t

  (** overflows silently *)
  val sub : t -> Span.t -> t

  (** overflows silently *)
  val next : t -> t

  (** overflows silently *)
  val prev : t -> t

  (** overflows silently *)
  val diff : t -> t -> Span.t

  (** overflows silently *)
  val abs_diff : t -> t -> Span.t

  val to_span_since_epoch : t -> Span.t
  val of_span_since_epoch : Span.t -> t
  val to_int63_ns_since_epoch : t -> Int63.t
  val of_int63_ns_since_epoch : Int63.t -> t

  (** Will raise on 32-bit platforms.  Consider [to_int63_ns_since_epoch] instead. *)
  val to_int_ns_since_epoch : t -> int

  val of_int_ns_since_epoch : int -> t

  (** [next_multiple ~base ~after ~interval] returns the smallest [time] of the form:

      {[
        time = base + k * interval
      ]}

      where [k >= 0] and [time > after].  It is an error if [interval <= 0].

      Supplying [~can_equal_after:true] allows the result to satisfy [time >= after].

      Overflows silently. *)
  val next_multiple
    :  ?can_equal_after:bool (** default is [false] *)
    -> base:t
    -> after:t
    -> interval:Span.t
    -> unit
    -> t

  val random : ?state:Random.State.t -> unit -> t
  val of_time : Time_float.t -> t
  val to_time : t -> Time_float.t

  module Utc : sig
    (** [to_date_and_span_since_start_of_day] computes the date and intraday-offset of a
        time in UTC.  It may be slower than [Core.Time_ns.to_date_ofday], as this
        function does not cache partial results while the latter does. *)
    val to_date_and_span_since_start_of_day : t -> Date0.t * Span.t

    (** The inverse of [to_date_and_span_since_start_of_day]. *)
    val of_date_and_span_since_start_of_day : Date0.t -> Span.t -> t
  end

  module Stable : sig
    module Alternate_sexp : sig
      module V1 : Stable_without_comparator with type t = Alternate_sexp.t
    end

    module Span : sig
      (** [V1] is currently only implemented in [Core]. *)
      module V2 : sig
        type t = Span.t [@@deriving hash]

        include Stable_int63able with type t := t
      end
    end

    module Ofday : sig
      module V1 : Stable_int63able with type t = Ofday.t
    end
  end
end
