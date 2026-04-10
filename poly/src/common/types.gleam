//// This module defines the core data structures used throughout the Poly framework.
//// It includes types for conversations, message parts, tool declarations,
//// and events emitted by the agent.

import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result

/// Represents a message in a conversation.
pub type Message {
  Message(
    /// The role of the message sender (e.g., "user", "model", "system").
    role: String,
    /// The individual parts that make up the message content.
    parts: List(Part),
  )
}

/// Represents a part of a message.
pub type Part {
  /// Regular text content.
  Text(text: String, signature: Option(String))
  /// Internal model thought or reasoning.
  Thought(thought: String, signature: Option(String))
  /// A request from the model to call a specific function.
  FunctionCall(name: String, args: decode.Dynamic, signature: Option(String))
  /// The result of a function execution.
  FunctionResponse(name: String, response: json.Json)
}

/// A collection of tools that the model can use.
pub type Tool {
  Tool(function_declarations: List(FunctionDeclaration))
}

/// The description of a single function available for the model to call.
pub type FunctionDeclaration {
  FunctionDeclaration(
    name: String,
    description: String,
    parameters: Option(json.Json),
  )
}

/// Converts a dynamic value (usually from an external API or FFI) into a JSON object.
/// This is used to normalize data before sending it to the LLM or processing tool responses.
pub fn dynamic_to_json(dyn: decode.Dynamic) -> json.Json {
  let encoders = [
    fn(d) { d |> decode.run(decode.string) |> result.map(json.string) },
    fn(d) { d |> decode.run(decode.int) |> result.map(json.int) },
    fn(d) { d |> decode.run(decode.float) |> result.map(json.float) },
    fn(d) { d |> decode.run(decode.bool) |> result.map(json.bool) },
  ]

  let simple_value = list.find_map(encoders, fn(encoder) { encoder(dyn) })

  case simple_value {
    Ok(j) -> j
    Error(_) -> {
      case decode.run(dyn, decode.list(decode.dynamic)) {
        Ok(l) -> json.array(l, dynamic_to_json)
        Error(_) -> {
          case decode.run(dyn, decode.optional(decode.bit_array)) {
            Ok(Some(_)) | Ok(None) -> json.null()
            _ -> {
              dyn
              |> get_map_fields
              |> list.map(fn(pair) { #(pair.0, dynamic_to_json(pair.1)) })
              |> json.object
            }
          }
        }
      }
    }
  }
}

@external(erlang, "maps", "to_list")
fn get_map_fields(a: decode.Dynamic) -> List(#(String, decode.Dynamic))

/// Events emitted by the agent during its execution loop.
/// These can be used to provide real-time feedback in a UI or for logging purposes.
pub type AgentEvent {
  /// Emitted when the model generates internal reasoning/thoughts.
  ThoughtEvent(text: String)
  /// Emitted just before a tool starts executing.
  ToolStartEvent(name: String, args: json.Json)
  /// Emitted after a tool finishes execution with its result.
  ToolResultEvent(name: String, result: json.Json)
}
