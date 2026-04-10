import common/types
import gleam/dynamic/decode
import gleam/json
import gleam/option.{None, Some}
import gleam/string
import gleeunit/should
import providers/gemini

pub fn message_with_text_to_json_test() {
  let msg = types.Message(role: "user", parts: [types.Text("Hello", None)])
  let json_str = gemini.message_to_json(msg) |> json.to_string

  json_str |> string.contains("\"role\":\"user\"") |> should.be_true
  json_str |> string.contains("\"text\":\"Hello\"") |> should.be_true
}

pub fn build_request_body_with_system_instruction_test() {
  let history = [
    types.Message(role: "user", parts: [types.Text("Hello", None)]),
  ]
  let body = gemini.build_request_body(history, Some("You are a bot"), [])

  body |> string.contains("\"system_instruction\"") |> should.be_true
  body |> string.contains("\"text\":\"You are a bot\"") |> should.be_true
}

pub fn message_with_function_call_to_json_test() {
  let assert Ok(args) =
    json.parse("{\"command\":\"ls\"}", using: decode.dynamic)

  let msg =
    types.Message(role: "model", parts: [
      types.FunctionCall(name: "execute", args: args, signature: Some("sig123")),
    ])

  let json_str = gemini.message_to_json(msg) |> json.to_string

  json_str
  |> string.contains("\"thoughtSignature\":\"sig123\"")
  |> should.be_true
  json_str |> string.contains("\"args\":{\"command\":\"ls\"}") |> should.be_true
}

pub fn tool_to_json_test() {
  let fd =
    types.FunctionDeclaration(
      name: "get_weather",
      description: "Gets the weather",
      parameters: Some(
        json.object([
          #("type", json.string("object")),
          #(
            "properties",
            json.object([
              #("location", json.object([#("type", json.string("string"))])),
            ]),
          ),
        ]),
      ),
    )

  let tool = types.Tool(function_declarations: [fd])
  let json_str = gemini.tool_to_json(tool) |> json.to_string

  json_str |> string.contains("\"name\":\"get_weather\"") |> should.be_true
  json_str |> string.contains("\"type\":\"object\"") |> should.be_true
}

pub fn decode_text_response_test() {
  let raw_json =
    "
    {
      \"candidates\": [
        {
          \"content\": {
            \"role\": \"model\",
            \"parts\": [
              {
                \"text\": \"Hello there!\",
                \"thoughtSignature\": \"sig_text\"
              }
            ]
          }
        }
      ]
    }
  "

  let result = gemini.decode_response(raw_json)

  result |> should.be_ok
  let assert Ok([types.Text(text, Some(sig))]) = result
  text |> should.equal("Hello there!")
  sig |> should.equal("sig_text")
}

pub fn decode_function_call_response_test() {
  let raw_json =
    "
    {
      \"candidates\": [
        {
          \"content\": {
            \"parts\": [
              {
                \"functionCall\": {
                  \"name\": \"get_time\",
                  \"args\": {
                    \"format\": \"24h\"
                  }
                },
                \"thoughtSignature\": \"sig_fc\"
              }
            ]
          }
        }
      ]
    }
  "

  let result = gemini.decode_response(raw_json)

  result |> should.be_ok
  let assert Ok([types.FunctionCall(name, _args, Some(sig))]) = result
  name |> should.equal("get_time")
  sig |> should.equal("sig_fc")
}

pub fn decode_thought_response_test() {
  let raw_json =
    "
    {
      \"candidates\": [
        {
          \"content\": {
            \"parts\": [
              {
                \"text\": \"I should check the time.\",
                \"thought\": true,
                \"thoughtSignature\": \"sig_thought\"
              }
            ]
          }
        }
      ]
    }
  "

  let result = gemini.decode_response(raw_json)

  result |> should.be_ok
  let assert Ok([types.Thought(thought, Some(sig))]) = result
  thought |> should.equal("I should check the time.")
  sig |> should.equal("sig_thought")
}

pub fn decode_empty_candidates_response_test() {
  let raw_json = "{\"candidates\": []}"
  let result = gemini.decode_response(raw_json)

  result |> should.be_ok
  result |> should.equal(Ok([]))
}

pub fn decode_malformed_json_test() {
  let raw_json = "invalid json"
  let result = gemini.decode_response(raw_json)
  result |> should.be_error
}

pub fn message_with_function_response_to_json_test() {
  let response_json = json.object([#("result", json.string("ok"))])
  let msg =
    types.Message(role: "function", parts: [
      types.FunctionResponse(name: "my_tool", response: response_json),
    ])

  let json_str = gemini.message_to_json(msg) |> json.to_string

  json_str |> string.contains("\"functionResponse\"") |> should.be_true
  json_str |> string.contains("\"name\":\"my_tool\"") |> should.be_true
  json_str
  |> string.contains("\"response\":{\"result\":\"ok\"}")
  |> should.be_true
}

pub fn build_request_body_minimal_test() {
  let history = [types.Message(role: "user", parts: [types.Text("Hi", None)])]
  let body = gemini.build_request_body(history, None, [])

  body |> string.contains("\"contents\"") |> should.be_true
  body |> string.contains("\"system_instruction\"") |> should.be_false
  body |> string.contains("\"tools\"") |> should.be_false
}
