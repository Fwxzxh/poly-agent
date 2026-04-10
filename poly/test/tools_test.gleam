import gleam/dynamic/decode
import gleam/json
import gleam/string
import gleeunit/should
import tools/fs
import tools/net
import tools/shell

// --- FFI Helper for Testing ---
// The tools use `cast_to_dynamic` (which is an identity cast in Erlang)
// to decode arguments. In tests, we need to ensure the `json.Json` value
// passed to the executor is in the format the decoder expects (an Erlang Map).
@external(erlang, "poly_ffi", "identity")
fn cast_to_json(a: any) -> json.Json

fn prepare_args(json_string: String) -> json.Json {
  let assert Ok(decoded) = json.parse(from: json_string, using: decode.dynamic)
  cast_to_json(decoded)
}

// --- Filesystem Tools Tests ---

pub fn fs_list_files_test() {
  let args = prepare_args("{\"directory\": \"src\"}")
  let tool = fs.list_files_tool()
  let response = tool.executor(args)

  let json_str = json.to_string(response)
  json_str |> string.contains("\"files\":") |> should.be_true
  json_str |> string.contains("agent.gleam") |> should.be_true
}

pub fn fs_read_file_test() {
  let args = prepare_args("{\"path\": \"gleam.toml\"}")
  let tool = fs.read_file_tool()
  let response = tool.executor(args)

  let json_str = json.to_string(response)
  json_str |> string.contains("poly") |> should.be_true
}

pub fn fs_read_file_not_found_test() {
  let args = prepare_args("{\"path\": \"non_existent_file_123.txt\"}")
  let tool = fs.read_file_tool()
  let response = tool.executor(args)

  let json_str = json.to_string(response)
  json_str |> string.contains("\"error\":") |> should.be_true
}

// --- Shell Tools Tests ---

pub fn shell_execute_command_test() {
  let args = prepare_args("{\"command\": \"echo 'hello poly'\"}")
  let tool = shell.execute_command_tool()
  let response = tool.executor(args)

  let json_str = json.to_string(response)
  json_str |> string.contains("\"status\":0") |> should.be_true
  json_str |> string.contains("hello poly") |> should.be_true
}

pub fn shell_execute_error_test() {
  let args = prepare_args("{\"command\": \"ls /non_existent_folder_xyz\"}")
  let tool = shell.execute_command_tool()
  let response = tool.executor(args)

  let json_str = json.to_string(response)
  // Status should be non-zero for a failing command
  json_str |> string.contains("\"status\":0") |> should.be_false
}

// --- Network Tools Tests ---

pub fn net_http_get_invalid_url_test() {
  let args = prepare_args("{\"url\": \"not-a-url\"}")
  let tool = net.http_get_tool()
  let response = tool.executor(args)

  let json_str = json.to_string(response)
  json_str |> string.contains("\"error\":") |> should.be_true
}

pub fn net_http_get_missing_arg_test() {
  let args = prepare_args("{}")
  let tool = net.http_get_tool()
  let response = tool.executor(args)

  let json_str = json.to_string(response)
  json_str
  |> string.contains("Missing or invalid 'url' argument")
  |> should.be_true
}
