## session.nim -- Combined Valkey + regula session.
{.experimental: "strict_funcs".}
import std/tables
import lattice, store, sync
type
  ValkeyRegulaSession* = object
    sync*: SyncSession
    inserts*: int
    retracts*: int
proc new_session*(set_fn: ValkeySetFn, del_fn: ValkeyDelFn,
                  prefix: string = "wme"): ValkeyRegulaSession =
  ValkeyRegulaSession(sync: new_sync(set_fn, del_fn, prefix))
proc insert*(s: var ValkeyRegulaSession, fact_type: string,
             fields: Table[string, string]): Result[string, BridgeError] =
  let r = s.sync.on_insert(fact_type, fields)
  if r.is_good: inc s.inserts
  r
proc retract*(s: var ValkeyRegulaSession, key: string): Result[void, BridgeError] =
  let r = s.sync.on_retract(key)
  if r.is_good: inc s.retracts
  r
