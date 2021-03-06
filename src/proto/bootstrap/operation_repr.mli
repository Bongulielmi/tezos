(**************************************************************************)
(*                                                                        *)
(*    Copyright (c) 2014 - 2016.                                          *)
(*    Dynamic Ledger Solutions, Inc. <contact@tezos.com>                  *)
(*                                                                        *)
(*    All rights reserved. No warranty, explicit or implicit, provided.   *)
(*                                                                        *)
(**************************************************************************)

(* Tezos Protocol Implementation - Low level Repr. of Operations *)

type operation = {
  hash: Operation_hash.t ;
  shell: Updater.shell_operation ;
  contents: proto_operation ;
  signature: Ed25519.signature option ;
}

and proto_operation =
  | Anonymous_operations of anonymous_operation list
  | Sourced_operations of sourced_operations

and anonymous_operation =
  | Seed_nonce_revelation of {
      level: Raw_level_repr.t ;
      nonce: Seed_repr.nonce ;
    }

and sourced_operations =
  | Manager_operations of {
      source: Contract_repr.contract ;
      public_key: Ed25519.public_key option ;
      fee: Tez_repr.tez ;
      counter: counter ;
      operations: manager_operation list ;
    }
  | Delegate_operations of {
      source: Ed25519.public_key ;
      operations: delegate_operation list ;
    }

and manager_operation =
  | Transaction of {
      amount: Tez_repr.tez ;
      parameters: Script_repr.expr option ;
      destination: Contract_repr.contract ;
    }
  | Origination of {
      manager: Ed25519.public_key_hash ;
      delegate: Ed25519.public_key_hash option ;
      script: Script_repr.t ;
      spendable: bool ;
      delegatable: bool ;
      credit: Tez_repr.tez ;
    }
  | Issuance of {
      asset: Asset_repr.t * Ed25519.public_key_hash ;
      amount: Tez_repr.tez ;
    }
  | Delegation of Ed25519.public_key_hash option

and delegate_operation =
  | Endorsement of {
      block: Block_hash.t ;
      slot: int ;
    }
  | Proposals of {
      period: Voting_period_repr.t ;
      proposals: Protocol_hash.t list ;
    }
  | Ballot of {
      period: Voting_period_repr.t ;
      proposal: Protocol_hash.t ;
      ballot: Vote_repr.ballot ;
    }

and counter = Int32.t

type error += Cannot_parse_operation

val parse:
  Operation_hash.t -> Updater.raw_operation -> operation tzresult

val parse_proto:
  MBytes.t ->
  (proto_operation * Ed25519.signature option) tzresult Lwt.t

type error += Invalid_signature
val check_signature:
  Ed25519.public_key -> operation -> unit tzresult Lwt.t

val forge: Updater.shell_operation -> proto_operation -> MBytes.t

val proto_operation_encoding:
  proto_operation Data_encoding.t

val unsigned_operation_encoding:
  (Updater.shell_operation * proto_operation) Data_encoding.t

val max_operation_data_length: int
