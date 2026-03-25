## load.nim -- Startup recovery from Valkey.
{.experimental: "strict_funcs".}
import std/[strutils, tables]
import basis/code/choice, store
type InsertFn* = proc(fact_type: string, fields: Table[string, string]): Choice[bool] {.raises: [].}
proc recover*(scan_fn: ValkeyScanFn, get_fn: ValkeyGetFn, insert_fn: InsertFn,
              prefix: string): Choice[int] =
  let keys = scan_fn(prefix)
  if keys.is_bad: return bad[int](keys.err)
  var count = 0
  for key in keys.val:
    let fields = get_fn(key)
    if fields.is_bad: continue
    let parts = key.split(":")
    let fact_type = if parts.len >= 2: parts[^2] else: "unknown"
    let r = insert_fn(fact_type, fields.val)
    if r.is_good: inc count
  good(count)
