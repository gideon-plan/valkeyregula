## notify.nim -- Valkey keyspace notifications -> WME insertions.
{.experimental: "strict_funcs".}

import lattice
type
  NotifyEvent* = object
    key*: string
    operation*: string  ## "set", "del", "hset"
  NotifyHandler* = proc(event: NotifyEvent): Result[void, BridgeError] {.raises: [].}
proc is_insert*(e: NotifyEvent): bool = e.operation in ["set", "hset"]
proc is_delete*(e: NotifyEvent): bool = e.operation == "del"
