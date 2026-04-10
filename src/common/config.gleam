//// This module centralizes the configuration logic for the Poly Agent.
//// It handles loading settings from environment variables and provides
//// a unified configuration type.

import dot_env/env
import gleam/result

/// Configuration settings for the Poly Agent.
pub type Config {
  Config(
    api_key: String,
    model: String,
    debug: Bool,
    verbose: Bool,
    streaming: Bool,
  )
}

/// Loads the configuration from environment variables.
pub fn load() -> Result(Config, String) {
  use api_key <- result.try(
    env.get_string("GOOGLE_API_KEY")
    |> result.replace_error("GOOGLE_API_KEY not found in environment"),
  )

  let model =
    env.get_string("GOOGLE_MODEL")
    |> result.unwrap("gemini-3.1-flash-lite-preview")
  let debug = get_bool_env("DEBUG", False)
  let verbose = get_bool_env("VERBOSE", False)
  let streaming = get_bool_env("STREAMING", False)

  Ok(Config(
    api_key: api_key,
    model: model,
    debug: debug,
    verbose: verbose,
    streaming: streaming,
  ))
}

fn get_bool_env(name: String, default: Bool) -> Bool {
  case env.get_string(name) {
    Ok("true") -> True
    Ok("false") -> False
    _ -> default
  }
}
