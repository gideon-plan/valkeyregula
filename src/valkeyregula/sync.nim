## sync.nim -- Write-through insert/retract/modify.
{.experimental: "strict_funcs".}
import std/tables
import basis/code/choice, store
type
  SyncSession* = object
    set_fn*: ValkeySetFn
    del_fn*: ValkeyDelFn
    prefix*: string
    next_id*: int
    synced*: int
proc new_sync*(set_fn: ValkeySetFn, del_fn: ValkeyDelFn,
               prefix: string = "wme"): SyncSession =
  SyncSession(set_fn: set_fn, del_fn: del_fn, prefix: prefix)
proc on_insert*(s: var SyncSession, fact_type: string,
                fields: Table[string, string]): Choice[string] =
  let key = wme_key(s.prefix, fact_type, s.next_id)
  inc s.next_id
  let r = store_wme(s.set_fn, key, fields)
  if r.is_good: inc s.synced
  if r.is_bad: return bad[string](r.err)
  good(key)
proc on_retract*(s: var SyncSession, key: string): Choice[bool] =
  delete_wme(s.del_fn, key)
