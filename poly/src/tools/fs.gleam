//// This module contains filesystem-related tools for the agent.

import gleam/dynamic/decode
import gleam/json
import gleam/string
import simplifile
import tools/utils

/// Returns the "read_file" tool.
pub fn read_file_tool() -> utils.Tool {
  utils.new(
    "read_file",
    "Reads the content of a file from the local filesystem.",
  )
  |> utils.with_string_param(
    "path",
    "The absolute or relative path to the file",
    required: True,
  )
  |> utils.build_tool(read_file_executor)
}

fn read_file_executor(args: json.Json) -> json.Json {
  let decoder = {
    use path <- decode.field("path", decode.string)
    decode.success(path)
  }

  case decode.run(cast_to_dynamic(args), decoder) {
    Ok(path) -> {
      case simplifile.read(path) {
        Ok(content) -> json.object([#("content", json.string(content))])
        Error(err) ->
          json.object([
            #(
              "error",
              json.string("Could not read file: " <> string.inspect(err)),
            ),
          ])
      }
    }
    Error(_) ->
      json.object([
        #("error", json.string("Missing or invalid 'path' argument")),
      ])
  }
}

/// Returns the "list_files" tool.
pub fn list_files_tool() -> utils.Tool {
  utils.new("list_files", "Lists all files in a given directory.")
  |> utils.with_string_param(
    "directory",
    "The directory path to list files from",
    required: True,
  )
  |> utils.build_tool(list_files_executor)
}

fn list_files_executor(args: json.Json) -> json.Json {
  let decoder = {
    use directory <- decode.field("directory", decode.string)
    decode.success(directory)
  }

  case decode.run(cast_to_dynamic(args), decoder) {
    Ok(dir) -> {
      case simplifile.read_directory(dir) {
        Ok(files) -> json.object([#("files", json.array(files, json.string))])
        Error(err) ->
          json.object([
            #(
              "error",
              json.string("Could not list directory: " <> string.inspect(err)),
            ),
          ])
      }
    }
    Error(_) ->
      json.object([
        #("error", json.string("Missing or invalid 'directory' argument")),
      ])
  }
}

@external(erlang, "poly_ffi", "identity")
fn cast_to_dynamic(a: json.Json) -> decode.Dynamic
