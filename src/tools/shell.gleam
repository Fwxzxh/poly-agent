//// This module contains tools for executing shell commands.

import gleam/dynamic/decode
import gleam/json
import tools/utils

/// Returns the `execute_command` tool.
///
/// This tool allows the agent to execute arbitrary shell commands on the
/// host system. It returns both the exit code and the command output
/// (or error message).
///
/// **Security Note:** This tool gives the agent significant power over the
/// host system. Use with caution.
pub fn execute_command_tool() -> utils.Tool {
  utils.new(
    "execute_command",
    "Executes a shell command on the local system and returns the output.",
  )
  |> utils.with_approval(True)
  |> utils.with_string_param(
    "command",
    "The shell command to execute (e.g., 'ls -la' or 'grep')",
    required: True,
  )
  |> utils.build_tool(execute_command_executor)
}

fn execute_command_executor(args: json.Json) -> json.Json {
  let decoder = {
    use command <- decode.field("command", decode.string)
    decode.success(command)
  }

  case decode.run(cast_to_dynamic(args), decoder) {
    Ok(command) -> {
      // Note: We use a simplified shell execution here.
      // In a production environment, we'd want more robust handling
      // of stderr and exit codes.
      case run_command(command) {
        #(0, stdout) ->
          json.object([
            #("status", json.int(0)),
            #("output", json.string(stdout)),
          ])
        #(code, output) ->
          json.object([
            #("status", json.int(code)),
            #("error", json.string(output)),
          ])
      }
    }
    Error(_) ->
      json.object([
        #("error", json.string("Missing or invalid 'command' argument")),
      ])
  }
}

@external(erlang, "poly_ffi", "identity")
fn cast_to_dynamic(a: json.Json) -> decode.Dynamic

@external(erlang, "poly_ffi", "run_command")
fn run_command(command: String) -> #(Int, String)
