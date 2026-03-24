{.experimental: "strict_funcs".}
import std/[unittest, tables]
import valkeyregula
suite "store":
  test "wme key format":
    check wme_key("wme", "temperature", 0) == "wme:temperature:0"
suite "sync":
  test "on insert":
    let mock_set: ValkeySetFn = proc(k: string, f: Table[string, string]): Result[void, BridgeError] {.raises: [].} =
      Result[void, BridgeError](ok: true)
    let mock_del: ValkeyDelFn = proc(k: string): Result[void, BridgeError] {.raises: [].} =
      Result[void, BridgeError](ok: true)
    var s = new_sync(mock_set, mock_del)
    let r = s.on_insert("temp", {"value": "25"}.toTable)
    check r.is_good
    check r.val == "wme:temp:0"
    check s.synced == 1
suite "notify":
  test "is insert":
    check is_insert(NotifyEvent(key: "k", operation: "hset"))
    check not is_insert(NotifyEvent(key: "k", operation: "del"))
suite "session":
  test "insert and retract":
    let mock_set: ValkeySetFn = proc(k: string, f: Table[string, string]): Result[void, BridgeError] {.raises: [].} =
      Result[void, BridgeError](ok: true)
    let mock_del: ValkeyDelFn = proc(k: string): Result[void, BridgeError] {.raises: [].} =
      Result[void, BridgeError](ok: true)
    var s = new_session(mock_set, mock_del)
    let key = s.insert("temp", {"v": "1"}.toTable)
    check key.is_good
    check s.inserts == 1
    let r = s.retract(key.val)
    check r.is_good
    check s.retracts == 1
