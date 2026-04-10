//// This module provides the `Tool` and `ToolBuilder` types, which are used to
//// define the capabilities of an agent.
////
//// A tool consists of two parts:
//// 1. A **declaration**: A JSON description of the function (name, description, parameters).
//// 2. An **executor**: A Gleam function that implements the tool's logic.

import common/types
import gleam/json
import gleam/list
import gleam/option.{Some}

/// A tool consists of a JSON declaration and an executor function.
pub type Tool {
  Tool(
    /// The declaration of the function as expected by the AI provider.
    declaration: types.FunctionDeclaration,
    /// Whether this tool requires manual approval before execution.
    requires_approval: Bool,
    /// The function that will be executed when the model requests it.
    /// It takes a JSON object of arguments and returns a JSON result.
    executor: fn(json.Json) -> json.Json,
  )
}

/// A builder to incrementally construct a `Tool` with type-safe parameters.
pub type ToolBuilder {
  ToolBuilder(
    name: String,
    description: String,
    requires_approval: Bool,
    properties: List(#(String, json.Json)),
    required: List(String),
  )
}

/// Start building a new tool with a name and a description.
pub fn new(name: String, description: String) -> ToolBuilder {
  ToolBuilder(
    name: name,
    description: description,
    requires_approval: False,
    properties: [],
    required: [],
  )
}

/// Sets whether the tool requires manual approval.
pub fn with_approval(builder: ToolBuilder, required: Bool) -> ToolBuilder {
  ToolBuilder(..builder, requires_approval: required)
}

/// Adds a string parameter to a tool's declaration.
pub fn with_string_param(
  builder: ToolBuilder,
  name: String,
  description: String,
  required required: Bool,
) -> ToolBuilder {
  let param =
    json.object([
      #("type", json.string("string")),
      #("description", json.string(description)),
    ])
  ToolBuilder(
    ..builder,
    properties: list.append(builder.properties, [#(name, param)]),
    required: case required {
      True -> list.append(builder.required, [name])
      False -> builder.required
    },
  )
}

/// Adds an integer parameter to a tool's declaration.
pub fn with_int_param(
  builder: ToolBuilder,
  name: String,
  description: String,
  required required: Bool,
) -> ToolBuilder {
  let param =
    json.object([
      #("type", json.string("integer")),
      #("description", json.string(description)),
    ])
  ToolBuilder(
    ..builder,
    properties: list.append(builder.properties, [#(name, param)]),
    required: case required {
      True -> list.append(builder.required, [name])
      False -> builder.required
    },
  )
}

/// Adds a boolean parameter to a tool's declaration.
pub fn with_bool_param(
  builder: ToolBuilder,
  name: String,
  description: String,
  required required: Bool,
) -> ToolBuilder {
  let param =
    json.object([
      #("type", json.string("boolean")),
      #("description", json.string(description)),
    ])
  ToolBuilder(
    ..builder,
    properties: list.append(builder.properties, [#(name, param)]),
    required: case required {
      True -> list.append(builder.required, [name])
      False -> builder.required
    },
  )
}

/// Completes the tool building by providing an executor function.
///
/// The executor should handle argument parsing (from JSON) and return
/// a JSON response.
pub fn build_tool(
  builder: ToolBuilder,
  executor: fn(json.Json) -> json.Json,
) -> Tool {
  let parameters =
    json.object([
      #("type", json.string("object")),
      #("properties", json.object(builder.properties)),
      #("required", json.array(builder.required, json.string)),
    ])

  let declaration =
    types.FunctionDeclaration(
      name: builder.name,
      description: builder.description,
      parameters: Some(parameters),
    )

  Tool(
    declaration: declaration,
    requires_approval: builder.requires_approval,
    executor: executor,
  )
}
