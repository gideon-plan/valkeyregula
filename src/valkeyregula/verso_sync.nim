## verso_sync.nim -- Changeset-based sync via verso Mutation stream.
##
## Converts WME insert/retract operations into verso Mutations for
## durable change tracking. Recovery replays the verso Trail.

{.experimental: "strict_funcs".}

import std/tables
import basis/code/choice
import basis/code/verso
import store

type
  VersoSyncSession* = object
    set_fn*: ValkeySetFn
    del_fn*: ValkeyDelFn
    prefix*: string
    next_id*: int
    mutations*: seq[Mutation]  ## In-memory mutation log

proc new_verso_sync*(set_fn: ValkeySetFn, del_fn: ValkeyDelFn,
                     prefix: string = "wme"): VersoSyncSession =
  VersoSyncSession(set_fn: set_fn, del_fn: del_fn, prefix: prefix)

proc on_insert*(s: var VersoSyncSession, fact_type: string,
                fields: Table[string, string]): Choice[string] =
  ## Insert a WME and record a verso Mutation.
  let key = wme_key(s.prefix, fact_type, s.next_id)
  inc s.next_id
  let r = store_wme(s.set_fn, key, fields)
  if r.is_bad: return bad[string](r.err)

  # Record mutation
  var deltas: seq[Delta] = @[]
  for k, v in fields:
    deltas.add(delta_add(k, v))
  var parent = if s.mutations.len > 0: s.mutations[^1].id else: ""
  var m = Mutation(
    parent: parent, actor: "valkeyregula", timestamp: int64(s.next_id),
    plan_version: 1, space: "home", partition: pWork,
    entities: @[entity(fact_type, key)],
    deltas: deltas,
  )
  stamp(m)
  s.mutations.add(m)
  good(key)

proc on_retract*(s: var VersoSyncSession, key: string): Choice[bool] =
  ## Retract a WME and record a verso Mutation.
  let r = delete_wme(s.del_fn, key)
  if r.is_bad: return bad[bool](r.err)

  var parent = if s.mutations.len > 0: s.mutations[^1].id else: ""
  var m = Mutation(
    parent: parent, actor: "valkeyregula", timestamp: int64(s.next_id),
    plan_version: 1, space: "home", partition: pWork,
    entities: @[entity("wme", key, Life.Done)],
    deltas: @[delta_remove("key", key)],
  )
  stamp(m)
  s.mutations.add(m)
  inc s.next_id
  good(true)

proc recover*(s: var VersoSyncSession, trail: seq[Mutation]): Choice[int] =
  ## Replay a verso Trail to recover WME state.
  ## Returns the number of WMEs recovered.
  var recovered = 0
  for m in trail:
    for e in m.entities:
      if e.life == Life.Done: continue
      var fields: Table[string, string]
      for d in m.deltas:
        if d.op == doAdd:
          fields[d.knot] = d.value
      if fields.len > 0:
        let r = store_wme(s.set_fn, e.instance_id, fields)
        if r.is_good: inc recovered
  good(recovered)
