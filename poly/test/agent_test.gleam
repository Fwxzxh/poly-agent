import agent
import common/types as types
import gleam/dynamic/decode
import gleam/json
import gleam/option.{None}
import gleeunit/should
import tools/utils

pub fn extract_text_test() {
  let parts = [types.Text("First", None), types.Text("Second", None)]

  agent.extract_text(parts) |> should.equal("First\nSecond")
}

pub fn extract_text_with_thought_test() {
  let parts = [
    types.Thought("I am thinking", None),
    types.Text("Here is the answer", None),
  ]

  agent.extract_text(parts) |> should.equal("Here is the answer")
}

pub fn extract_text_only_thought_test() {
  let parts = [types.Thought("Thinking really hard...", None)]

  agent.extract_text(parts) |> should.equal("Thinking really hard...")
}

pub fn get_function_calls_test() {
  // Use json.parse with decode.dynamic to get a Dynamic value for the test
  let assert Ok(args) = json.parse("{}", using: decode.dynamic)

  let parts = [types.Text("Some text", None), types.FunctionCall("my_tool", args, None)]

  let calls = agent.get_function_calls(parts)

  case calls {
    [#("my_tool", _)] -> Nil
    _ -> panic as "Expected one function call named 'my_tool'"
  }
}

pub fn get_function_calls_empty_test() {
  let parts = [types.Text("No tools here", None)]
  agent.get_function_calls(parts) |> should.equal([])
}

pub fn execute_tools_test() {
  let assert Ok(args) = json.parse("{}", using: decode.dynamic)
  let calls = [#("test_tool", args)]

  let tool =
    utils.new("test_tool", "A test tool")
    |> utils.build_tool(fn(_) { json.string("success") })

  let responses = agent.execute_tools(calls, [tool], fn(_) { Nil })

  let assert [types.FunctionResponse(name, response)] = responses
  name |> should.equal("test_tool")
  json.to_string(response) |> should.equal("\"success\"")
}

pub fn execute_tools_not_found_test() {
  let assert Ok(args) = json.parse("{}", using: decode.dynamic)
  let calls = [#("unknown", args)]

  let responses = agent.execute_tools(calls, [], fn(_) { Nil })

  let assert [types.FunctionResponse(name, response)] = responses
  name |> should.equal("unknown")
  json.to_string(response) |> should.equal("{\"error\":\"Tool not found\"}")
}
