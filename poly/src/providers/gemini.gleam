//// This module provides the Gemini provider implementation.
//// It handles the conversion between common types and the JSON format expected by Gemini.

import common/types
import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/httpc
import gleam/int
import gleam/io
import gleam/json
import gleam/option.{type Option, None, Some}
import gleam/string

import providers/interface as provider

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
  let part_decoder =
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

  let decoder = {
    use parts_list <- decode.field(
      "candidates",
      decode.list(decode.at(["content", "parts"], decode.list(part_decoder))),
    )
    case parts_list {
      [parts, ..] -> decode.success(parts)
      [] -> decode.success([])
    }
  }

  json.parse(from: json_string, using: decoder)
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
) -> Result(List(types.Part), Nil) {
  let url =
    "https://generativelanguage.googleapis.com/v1beta/models/"
    <> model
    <> ":generateContent?key="
    <> api_key

  let body = build_request_body(history, system_instruction, tool_declarations)

  case debug {
    True -> {
      io.println("--- DEBUG: Request Body ---")
      io.println(body)
      io.println("---------------------------")
    }
    False -> Nil
  }

  let assert Ok(req) = request.to(url)
  let req =
    req
    |> request.set_method(http.Post)
    |> request.set_body(body)
    |> request.set_header("content-type", "application/json")

  let assert Ok(resp) = httpc.send(req)

  case debug {
    True -> {
      io.println("--- DEBUG: Response Body ---")
      io.println(resp.body)
      io.println("----------------------------")
    }
    False -> Nil
  }

  case decode_response(resp.body) {
    Ok(parts) -> Ok(parts)
    Error(e) -> {
      io.println("--- API Error / Unexpected Response ---")
      io.println("Status: " <> int.to_string(resp.status))
      io.println("Body: " <> resp.body)
      io.println("Error details: " <> string.inspect(e))
      Error(Nil)
    }
  }
}
