import common/types as types
import gleam/json
import gleam/list
import gleam/option.{Some}

/// A tool consists of a JSON declaration and an executor function.
pub type Tool {
  Tool(
    /// The declaration of the function as expected by the AI provider.
    declaration: types.FunctionDeclaration,
    /// The function that will be executed when the model requests it.
    executor: fn(json.Json) -> json.Json,
  )
}

pub type ToolBuilder {
  ToolBuilder(
    name: String,
    description: String,
    properties: List(#(String, json.Json)),
    required: List(String),
  )
}

/// Start building a new tool.
pub fn new(name: String, description: String) -> ToolBuilder {
  ToolBuilder(
    name: name,
    description: description,
    properties: [],
    required: [],
  )
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

/// Completes the tool building by providing an executor.
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

  Tool(declaration: declaration, executor: executor)
}
