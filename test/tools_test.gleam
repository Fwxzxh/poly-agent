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

pub fn fs_list_files_recursive_test() {
  let args = prepare_args("{\"directory\": \"src\", \"recursive\": true}")
  let tool = fs.list_files_tool()
  let response = tool.executor(args)

  let json_str = json.to_string(response)
  json_str |> string.contains("\"files\":") |> should.be_true
  // Should contain files from subdirectories
  json_str |> string.contains("gemini.gleam") |> should.be_true
}

pub fn fs_write_file_test() {
  let path = "test_write.tmp"
  let content = "hello test content"
  let args =
    prepare_args(
      "{\"path\": \"" <> path <> "\", \"content\": \"" <> content <> "\"}",
    )
  let tool = fs.write_file_tool()
  let response = tool.executor(args)

  let json_str = json.to_string(response)
  json_str |> string.contains("\"status\":\"success\"") |> should.be_true

  // Verify file was written (using read_file tool)
  let read_args = prepare_args("{\"path\": \"" <> path <> "\"}")
  let read_tool = fs.read_file_tool()
  let read_response = read_tool.executor(read_args)
  json.to_string(read_response) |> string.contains(content) |> should.be_true
}

pub fn fs_grep_test() {
  let path = "test_grep.tmp"
  let content = "line one\\nline match two\\nline three"

  // Create file first
  let write_args =
    prepare_args(
      "{\"path\": \"" <> path <> "\", \"content\": \"" <> content <> "\"}",
    )
  let write_tool = fs.write_file_tool()
  write_tool.executor(write_args)

  let args =
    prepare_args("{\"path\": \"" <> path <> "\", \"pattern\": \"match\"}")
  let tool = fs.grep_tool()
  let response = tool.executor(args)

  let json_str = json.to_string(response)
  json_str |> string.contains("\"line\":2") |> should.be_true
  json_str |> string.contains("line match two") |> should.be_true
  json_str |> string.contains("line one") |> should.be_false
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
