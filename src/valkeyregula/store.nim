## store.nim -- WME -> Valkey hash mapping.
{.experimental: "strict_funcs".}
import std/tables
import lattice
type
  ValkeySetFn* = proc(key: string, fields: Table[string, string]): Result[void, BridgeError] {.raises: [].}
  ValkeyDelFn* = proc(key: string): Result[void, BridgeError] {.raises: [].}
  ValkeyGetFn* = proc(key: string): Result[Table[string, string], BridgeError] {.raises: [].}
  ValkeyScanFn* = proc(prefix: string): Result[seq[string], BridgeError] {.raises: [].}
proc wme_key*(prefix, fact_type: string, id: int): string =
  prefix & ":" & fact_type & ":" & $id
proc store_wme*(set_fn: ValkeySetFn, key: string,
                fields: Table[string, string]): Result[void, BridgeError] =
  set_fn(key, fields)
proc delete_wme*(del_fn: ValkeyDelFn, key: string): Result[void, BridgeError] =
  del_fn(key)
