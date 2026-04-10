//// This module contains filesystem-related tools for the agent.

import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/string
import simplifile
import tools/utils

/// Returns the `read_file` tool.
///
/// This tool allows the agent to read the content of any file on the local
/// filesystem. It takes a `path` argument.
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

/// Returns the `list_files` tool.
///
/// This tool allows the agent to see what files are available in a directory.
/// It takes a `directory` argument and an optional `recursive` flag.
pub fn list_files_tool() -> utils.Tool {
  utils.new("list_files", "Lists all files in a given directory.")
  |> utils.with_string_param(
    "directory",
    "The directory path to list files from",
    required: True,
  )
  |> utils.with_bool_param(
    "recursive",
    "Whether to list files recursively in subdirectories",
    required: False,
  )
  |> utils.build_tool(list_files_executor)
}

/// Returns the `grep` tool.
///
/// This tool allows searching for a pattern within a file.
pub fn grep_tool() -> utils.Tool {
  utils.new(
    "grep",
    "Searches for a pattern in a file and returns matching lines.",
  )
  |> utils.with_string_param(
    "path",
    "The path to the file to search in",
    required: True,
  )
  |> utils.with_string_param(
    "pattern",
    "The text or regex pattern to search for",
    required: True,
  )
  |> utils.build_tool(grep_executor)
}

/// Returns the `write_file` tool.
///
/// This tool allows the agent to create or overwrite a file with specific content.
/// It takes `path` and `content` arguments.
pub fn write_file_tool() -> utils.Tool {
  utils.new("write_file", "Writes content to a file on the local filesystem.")
  |> utils.with_string_param(
    "path",
    "The absolute or relative path to the file",
    required: True,
  )
  |> utils.with_string_param(
    "content",
    "The content to write to the file",
    required: True,
  )
  |> utils.build_tool(write_file_executor)
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

fn write_file_executor(args: json.Json) -> json.Json {
  let decoder = {
    use path <- decode.field("path", decode.string)
    use content <- decode.field("content", decode.string)
    decode.success(#(path, content))
  }

  case decode.run(cast_to_dynamic(args), decoder) {
    Ok(#(path, content)) -> {
      case simplifile.write(to: path, contents: content) {
        Ok(_) -> json.object([#("status", json.string("success"))])
        Error(err) ->
          json.object([
            #(
              "error",
              json.string("Could not write file: " <> string.inspect(err)),
            ),
          ])
      }
    }
    Error(_) ->
      json.object([
        #(
          "error",
          json.string("Missing or invalid 'path' or 'content' arguments"),
        ),
      ])
  }
}

fn list_files_executor(args: json.Json) -> json.Json {
  let decoder = {
    use directory <- decode.field("directory", decode.string)
    use recursive <- decode.optional_field("recursive", False, decode.bool)
    decode.success(#(directory, recursive))
  }

  case decode.run(cast_to_dynamic(args), decoder) {
    Ok(#(dir, recursive)) -> {
      let result = case recursive {
        True -> simplifile.get_files(dir)
        False -> simplifile.read_directory(dir)
      }
      case result {
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

fn grep_executor(args: json.Json) -> json.Json {
  let decoder = {
    use path <- decode.field("path", decode.string)
    use pattern <- decode.field("pattern", decode.string)
    decode.success(#(path, pattern))
  }

  case decode.run(cast_to_dynamic(args), decoder) {
    Ok(#(path, pattern)) -> {
      case simplifile.read(path) {
        Ok(content) -> {
          let lines = string.split(content, on: "\n")
          let matches =
            list.index_map(lines, fn(line, index) { #(index + 1, line) })
            |> list.filter(fn(pair) { string.contains(pair.1, pattern) })
            |> list.map(fn(pair) {
              json.object([
                #("line", json.int(pair.0)),
                #("content", json.string(pair.1)),
              ])
            })

          json.object([#("matches", json.array(matches, identity))])
        }
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
        #(
          "error",
          json.string("Missing or invalid 'path' or 'pattern' arguments"),
        ),
      ])
  }
}

fn identity(x: a) -> a {
  x
}

@external(erlang, "poly_ffi", "identity")
fn cast_to_dynamic(a: json.Json) -> decode.Dynamic
