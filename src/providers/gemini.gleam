//// This module provides the Gemini provider implementation.
//// It handles the conversion between common types and the JSON format expected by Gemini.

import common/types
import gleam/bit_array
import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/httpc
import gleam/int
import gleam/io
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string

import providers/interface as provider

/// Creates a new `Provider` instance for Google Gemini.
///
/// This provider uses the `v1beta` API which supports "Thinking" (reasoning)
/// and function calling.
pub fn gemini_provider() -> provider.Provider {
  provider.Provider(name: "gemini", call: call)
}

/// Encodes a `Message` into a JSON object compatible with Gemini API.
pub fn message_to_json(message: types.Message) -> json.Json {
  json.object([
    #("role", json.string(message.role)),
    #("parts", json.array(message.parts, part_to_json)),
  ])
}

/// Encodes a single `Part` of a message into JSON.
pub fn part_to_json(part: types.Part) -> json.Json {
  case part {
    types.Text(text, signature) -> {
      let fields = [#("text", json.string(text))]
      add_signature(fields, signature)
    }
    types.Thought(thought, signature) -> {
      let fields = [
        #("text", json.string(thought)),
        #("thought", json.bool(True)),
      ]
      add_signature(fields, signature)
    }
    types.FunctionCall(name, args, signature) -> {
      let fields = [
        #(
          "functionCall",
          json.object([
            #("name", json.string(name)),
            #("args", types.dynamic_to_json(args)),
          ]),
        ),
      ]
      add_signature(fields, signature)
    }
    types.FunctionResponse(name, response) ->
      json.object([
        #(
          "functionResponse",
          json.object([#("name", json.string(name)), #("response", response)]),
        ),
      ])
  }
}

fn add_signature(
  fields: List(#(String, json.Json)),
  signature: Option(String),
) -> json.Json {
  case signature {
    Some(s) -> json.object([#("thoughtSignature", json.string(s)), ..fields])
    None -> json.object(fields)
  }
}

/// Encodes a `Tool` (list of function declarations) into JSON.
pub fn tool_to_json(tool: types.Tool) -> json.Json {
  json.object([
    #(
      "function_declarations",
      json.array(tool.function_declarations, fn(fd) {
        let fields = [
          #("name", json.string(fd.name)),
          #("description", json.string(fd.description)),
        ]
        let fields = case fd.parameters {
          Some(params) -> [#("parameters", params), ..fields]
          None -> fields
        }
        json.object(fields)
      }),
    ),
  ])
}

/// Decodes a JSON response string from Gemini into a list of message parts.
pub fn decode_response(
  json_string: String,
) -> Result(List(types.Part), json.DecodeError) {
  json.parse(from: json_string, using: candidate_list_decoder())
}

/// Constructs the JSON request body for the Gemini API.
pub fn build_request_body(
  history: List(types.Message),
  system_instruction: Option(String),
  tool_declarations: List(types.FunctionDeclaration),
) -> String {
  let contents = #("contents", json.array(history, message_to_json))

  let generation_config = #(
    "generationConfig",
    json.object([
      #(
        "thinkingConfig",
        json.object([
          #("includeThoughts", json.bool(True)),
          #("thinkingBudget", json.int(8192)),
        ]),
      ),
    ]),
  )

  let mut_fields = [contents, generation_config]

  let mut_fields = case system_instruction {
    Some(instr) -> [
      #(
        "system_instruction",
        json.object([
          #(
            "parts",
            json.array([json.object([#("text", json.string(instr))])], identity),
          ),
        ]),
      ),
      ..mut_fields
    ]
    None -> mut_fields
  }

  let fields = case tool_declarations {
    [] -> mut_fields
    _ -> [
      #("tools", json.array([types.Tool(tool_declarations)], tool_to_json)),
      ..mut_fields
    ]
  }

  json.object(fields) |> json.to_string
}

fn identity(x: a) -> a {
  x
}

/// Makes the HTTP request to the Gemini API.
pub fn call(
  history: List(types.Message),
  system_instruction: Option(String),
  api_key: String,
  model: String,
  tool_declarations: List(types.FunctionDeclaration),
  debug: Bool,
  streaming: Bool,
  on_part: fn(types.Part) -> Nil,
) -> Result(List(types.Part), Nil) {
  let url = get_url(model, api_key, streaming)
  let body = build_request_body(history, system_instruction, tool_declarations)

  case debug {
    True -> {
      io.println("--- DEBUG: Request Body ---")
      io.println(body)
      io.println("---------------------------")
    }
    False -> Nil
  }

  case streaming {
    True -> execute_streaming_call(url, body, on_part)
    False -> execute_standard_call(url, body, debug)
  }
}

fn get_url(model: String, api_key: String, streaming: Bool) -> String {
  let endpoint = case streaming {
    True -> "streamGenerateContent"
    False -> "generateContent"
  }

  "https://generativelanguage.googleapis.com/v1beta/models/"
  <> model
  <> ":"
  <> endpoint
  <> "?key="
  <> api_key
}

fn execute_standard_call(
  url: String,
  body: String,
  debug: Bool,
) -> Result(List(types.Part), Nil) {
  use req <- result.try(
    request.to(url)
    |> result.map_error(fn(_) {
      io.println("--- URL Error ---")
      Nil
    }),
  )

  let req =
    req
    |> request.set_method(http.Post)
    |> request.set_body(body)
    |> request.set_header("content-type", "application/json")

  use resp <- result.try(
    httpc.send(req)
    |> result.map_error(fn(_) {
      io.println("--- Network Error ---")
      Nil
    }),
  )

  case debug {
    True -> {
      io.println("--- DEBUG: Response Body ---")
      io.println(resp.body)
      io.println("----------------------------")
    }
    False -> Nil
  }

  case resp.status {
    200 -> {
      case decode_response(resp.body) {
        Ok(parts) -> Ok(parts)
        Error(e) -> {
          io.println("--- API Error / Unexpected Response ---")
          io.println("Error decoding response: " <> string.inspect(e))
          Error(Nil)
        }
      }
    }
    _ -> {
      io.println("--- API Error ---")
      io.println("Status: " <> int.to_string(resp.status))
      io.println("Body: " <> resp.body)
      Error(Nil)
    }
  }
}

fn execute_streaming_call(
  url: String,
  body: String,
  on_part: fn(types.Part) -> Nil,
) -> Result(List(types.Part), Nil) {
  // For streaming, our robust Erlang FFI gives us complete JSON objects one by one
  let handle_chunk = fn(chunk) {
    case bit_array.to_string(chunk) {
      Ok(json_str) -> {
        // Parse this single chunk as a response
        case decode_response(json_str) {
          Ok(parts) -> list.each(parts, on_part)
          Error(_) -> Nil
        }
      }
      Error(_) -> Nil
    }
  }

  use full_bit_array <- result.try(stream_request(url, body, handle_chunk))

  case bit_array.to_string(full_bit_array) {
    Ok(full_body) -> {
      // The full body is a JSON array [{}, {}]
      // We already streamed the parts, but we need to return the full list
      case decode_stream_response(full_body, on_part) {
        Ok(parts) -> Ok(parts)
        Error(_) -> Error(Nil)
      }
    }
    Error(_) -> Error(Nil)
  }
}

@external(erlang, "poly_ffi", "stream_request")
fn stream_request(
  url: String,
  body: String,
  on_chunk: fn(BitArray) -> Nil,
) -> Result(BitArray, Nil)

pub fn decode_stream_response(
  json_string: String,
  _on_part: fn(types.Part) -> Nil,
) -> Result(List(types.Part), json.DecodeError) {
  // Gemini stream returns a JSON array of response objects
  let decoder = decode.list(candidate_list_decoder())

  case json.parse(from: json_string, using: decoder) {
    Ok(chunks) -> {
      let all_parts = list.flatten(chunks)
      // Call on_part for each part if we want to simulate the stream after receiving all
      // Actually, the real streaming happens in the FFI and calls a callback.
      // But for the final result return, we flatten everything.
      Ok(all_parts)
    }
    Error(e) -> Error(e)
  }
}

fn candidate_list_decoder() -> decode.Decoder(List(types.Part)) {
  decode.one_of(
    {
      use parts_list <- decode.field(
        "candidates",
        decode.list(decode.at(["content", "parts"], decode.list(part_decoder()))),
      )
      case parts_list {
        [parts, ..] -> decode.success(parts)
        [] -> decode.success([])
      }
    },
    [decode.success([])],
  )
}

fn part_decoder() -> decode.Decoder(types.Part) {
  decode.one_of(
    {
      use text <- decode.field("text", decode.string)
      use sig <- decode.optional_field(
        "thoughtSignature",
        None,
        decode.optional(decode.string),
      )
      use is_thought <- decode.optional_field("thought", False, decode.bool)
      case is_thought {
        True -> decode.success(types.Thought(text, sig))
        False -> decode.success(types.Text(text, sig))
      }
    },
    [
      {
        use name <- decode.subfield(["functionCall", "name"], decode.string)
        use args <- decode.subfield(["functionCall", "args"], decode.dynamic)
        use sig <- decode.optional_field(
          "thoughtSignature",
          None,
          decode.optional(decode.string),
        )
        decode.success(types.FunctionCall(name, args, sig))
      },
    ],
  )
}
