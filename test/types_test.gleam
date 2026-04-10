import common/types
import gleam/dynamic/decode
import gleam/json
import gleeunit/should

pub fn string_to_json_test() {
  let assert Ok(dyn) = json.parse("\"hello\"", decode.dynamic)
  types.dynamic_to_json(dyn) |> json.to_string |> should.equal("\"hello\"")
}

pub fn int_to_json_test() {
  let assert Ok(dyn) = json.parse("123", decode.dynamic)
  types.dynamic_to_json(dyn) |> json.to_string |> should.equal("123")
}

pub fn float_to_json_test() {
  let assert Ok(dyn) = json.parse("1.25", decode.dynamic)
  types.dynamic_to_json(dyn) |> json.to_string |> should.equal("1.25")
}

pub fn bool_to_json_test() {
  let assert Ok(dyn) = json.parse("true", decode.dynamic)
  types.dynamic_to_json(dyn) |> json.to_string |> should.equal("true")
}

pub fn list_to_json_test() {
  let assert Ok(dyn) = json.parse("[1, \"two\", true]", decode.dynamic)
  types.dynamic_to_json(dyn)
  |> json.to_string
  |> should.equal("[1,\"two\",true]")
}

pub fn object_to_json_test() {
  let assert Ok(dyn) = json.parse("{\"a\": 1, \"b\": \"text\"}", decode.dynamic)
  let json_str = types.dynamic_to_json(dyn) |> json.to_string
  // Order in Erlang maps for small sets of keys is usually deterministic
  json_str |> should.equal("{\"a\":1,\"b\":\"text\"}")
}

pub fn nested_to_json_test() {
  let input = "{\"inner\":[1,2],\"val\":{\"ok\":true}}"
  let assert Ok(dyn) = json.parse(input, decode.dynamic)
  let json_str = types.dynamic_to_json(dyn) |> json.to_string
  json_str |> should.equal(input)
}

pub fn null_to_json_test() {
  let assert Ok(dyn) = json.parse("null", decode.dynamic)
  types.dynamic_to_json(dyn) |> json.to_string |> should.equal("null")
}

pub fn agent_event_types_test() {
  // Just verifying we can construct these for future use
  let _ = types.ThoughtEvent("thinking")
  let _ = types.ToolStartEvent("tool", json.object([]))
  let _ = types.ToolResultEvent("tool", json.string("done"))
  True |> should.be_true
}
