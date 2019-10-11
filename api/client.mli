open Capnp_rpc_lwt

type git_ref = string
(** A Git reference. e.g. "refs/heads/master" *)

type git_hash = string

type variant = string

module Ref_map : Map.S with type key = git_ref

type job_info = {
  variant : variant;
  outcome : Raw.Reader.JobInfo.State.unnamed_union_t;
}

val pp_state : Raw.Reader.JobInfo.State.unnamed_union_t Fmt.t

module Commit : sig
  type t = Raw.Client.Commit.t Capability.t
  (** A single commit being tested. *)

  val jobs : t -> (job_info list, [> `Capnp of Capnp_rpc.Error.t ]) Lwt_result.t

  val job_of_variant : t -> variant -> Current_rpc.Job.t
  (** [job_of_variant t] is the (most recent) OCurrent job for this variant. *)

  val refs : t -> (git_ref list, [> `Capnp of Capnp_rpc.Error.t ]) Lwt_result.t
  (** [refs t] is the list of Git references that have this commit as their head. *)
end

module Repo : sig
  type t = Raw.Client.Repo.t Capability.t
  (** A GitHub repository that is tested by ocaml-ci. *)

  val refs : t -> (git_hash Ref_map.t, [> `Capnp of Capnp_rpc.Error.t ]) Lwt_result.t
  (** [refs t] returns the known Git references (branches and pull requests) that ocaml-ci
      is monitoring, along with the current head of each one. *)

  val commit_of_hash : t -> git_hash -> Commit.t
  (** [commit_of_hash t hash] is the commit [hash] in this repository. *)

  val commit_of_ref : t -> git_ref -> Commit.t
  (** [commit_of_ref t gref] is the commit at the head of Git reference [gref]. *)
end

module Org : sig
  type t = Raw.Client.Org.t Capability.t
  (** A GitHub organisation. *)

  val repo : t -> string -> Repo.t
  (** [repo t name] is the GitHub organisation at "https://github.com/$owner/$name".
      It returns an error if ocaml-ci doesn't know about this repository. *)

  val repos : t -> (string list, [> `Capnp of Capnp_rpc.Error.t ]) Lwt_result.t
end

module CI : sig
  type t = Raw.Client.CI.t Capability.t
  (** The top-level object for ocaml-ci. *)

  val org : t -> string -> Org.t
  (** [org t owner] is the GitHub organisation at "https://github.com/$owner".
      It returns an error if ocaml-ci doesn't know about this organisation. *)

  val orgs : t -> (string list, [> `Capnp of Capnp_rpc.Error.t ]) Lwt_result.t
end
