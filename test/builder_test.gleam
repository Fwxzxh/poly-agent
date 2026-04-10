import gleam/json
import gleam/option.{Some}
import gleeunit/should
import tools/utils

pub fn basic_builder_test() {
  let tool =
    utils.new("test_tool", "Description")
    |> utils.build_tool(fn(_) { json.null() })

  tool.declaration.name |> should.equal("test_tool")
  tool.declaration.description |> should.equal("Description")

  let assert Some(params) = tool.declaration.parameters
  let json_str = json.to_string(params)

  json_str
  |> should.equal("{\"type\":\"object\",\"properties\":{},\"required\":[]}")
}

pub fn string_param_test() {
  let tool =
    utils.new("greet", "Greets a user")
    |> utils.with_string_param("name", "The user name", required: True)
    |> utils.build_tool(fn(_) { json.null() })

  let assert Some(params) = tool.declaration.parameters
  let json_str = json.to_string(params)

  json_str
  |> should.equal(
    "{\"type\":\"object\",\"properties\":{\"name\":{\"type\":\"string\",\"description\":\"The user name\"}},\"required\":[\"name\"]}",
  )
}

pub fn int_param_test() {
  let tool =
    utils.new("add", "Adds a number")
    |> utils.with_int_param("value", "The number to add", required: False)
    |> utils.build_tool(fn(_) { json.null() })

  let assert Some(params) = tool.declaration.parameters
  let json_str = json.to_string(params)

  json_str
  |> should.equal(
    "{\"type\":\"object\",\"properties\":{\"value\":{\"type\":\"integer\",\"description\":\"The number to add\"}},\"required\":[]}",
  )
}

pub fn multiple_params_test() {
  let tool =
    utils.new("complex", "A complex tool")
    |> utils.with_string_param("a", "string a", required: True)
    |> utils.with_int_param("b", "int b", required: False)
    |> utils.with_string_param("c", "string c", required: True)
    |> utils.build_tool(fn(_) { json.null() })

  let assert Some(params) = tool.declaration.parameters
  let json_str = json.to_string(params)

  // Verify properties exist
  json_str
  |> should.equal(
    "{\"type\":\"object\",\"properties\":{\"a\":{\"type\":\"string\",\"description\":\"string a\"},\"b\":{\"type\":\"integer\",\"description\":\"int b\"},\"c\":{\"type\":\"string\",\"description\":\"string c\"}},\"required\":[\"a\",\"c\"]}",
  )
}

pub fn executor_test() {
  let tool =
    utils.new("echo", "Echoes input")
    |> utils.build_tool(fn(args) { args })

  let input = json.object([#("hello", json.string("world"))])
  let result = tool.executor(input)

  result |> should.equal(input)
}
