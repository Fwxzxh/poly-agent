//// This module contains network-related tools.

import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/httpc
import gleam/json
import gleam/string
import tools/utils

/// Returns the "http_get" tool.
pub fn http_get_tool() -> utils.Tool {
  utils.new(
    "http_get",
    "Performs an HTTP GET request and returns the response body.",
  )
  |> utils.with_string_param("url", "The URL to fetch", required: True)
  |> utils.build_tool(http_get_executor)
}

fn http_get_executor(args: json.Json) -> json.Json {
  let decoder = {
    use url <- decode.field("url", decode.string)
    decode.success(url)
  }

  case decode.run(cast_to_dynamic(args), decoder) {
    Ok(url) -> {
      case request.to(url) {
        Ok(req) -> {
          let req = req |> request.set_method(http.Get)
          case httpc.send(req) {
            Ok(resp) -> json.object([#("body", json.string(resp.body))])
            Error(err) ->
              json.object([
                #(
                  "error",
                  json.string("HTTP request failed: " <> string.inspect(err)),
                ),
              ])
          }
        }
        Error(_) -> json.object([#("error", json.string("Invalid URL"))])
      }
    }
    Error(_) ->
      json.object([#("error", json.string("Missing or invalid 'url' argument"))])
  }
}

@external(erlang, "poly_ffi", "identity")
fn cast_to_dynamic(a: json.Json) -> decode.Dynamic
