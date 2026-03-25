## store.nim -- WME -> Valkey hash mapping.
{.experimental: "strict_funcs".}
import std/tables
import basis/code/choice
type
  ValkeySetFn* = proc(key: string, fields: Table[string, string]): Choice[bool] {.raises: [].}
  ValkeyDelFn* = proc(key: string): Choice[bool] {.raises: [].}
  ValkeyGetFn* = proc(key: string): Choice[Table[string, string]] {.raises: [].}
  ValkeyScanFn* = proc(prefix: string): Choice[seq[string]] {.raises: [].}
proc wme_key*(prefix, fact_type: string, id: int): string =
  prefix & ":" & fact_type & ":" & $id
proc store_wme*(set_fn: ValkeySetFn, key: string,
                fields: Table[string, string]): Choice[bool] =
  set_fn(key, fields)
proc delete_wme*(del_fn: ValkeyDelFn, key: string): Choice[bool] =
  del_fn(key)
