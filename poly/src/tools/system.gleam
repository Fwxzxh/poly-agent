//// This module provides system-level information for the agent.
//// It retrieves environment details to give the AI context about the host.

import gleam/string
import simplifile

/// Represents basic information about the environment where the agent is running.
pub type SystemInfo {
  SystemInfo(
    os_type: String,
    os_version: String,
    architecture: String,
    current_user: String,
    working_directory: String,
  )
}

/// Gathers information from the operating system and current environment.
pub fn get_info() -> SystemInfo {
  let #(os_type, os_version, arch, user) = get_raw_system_info()
  let cwd = case simplifile.current_directory() {
    Ok(path) -> path
    Error(_) -> "unknown"
  }

  SystemInfo(
    os_type: string.inspect(os_type),
    os_version: string.inspect(os_version),
    architecture: string.inspect(arch),
    current_user: string.inspect(user),
    working_directory: cwd,
  )
}

/// Formats the gathered system information as a text block for the system prompt.
pub fn format_as_context(info: SystemInfo) -> String {
  "System Context:
- OS: " <> info.os_type <> " (" <> info.os_version <> ")
- Architecture: " <> info.architecture <> "
- User: " <> info.current_user <> "
- Working Directory: " <> info.working_directory <> "
- Date: " <> get_date()
}

@external(erlang, "poly_ffi", "get_system_info")
fn get_raw_system_info() -> #(any, any, any, any)

fn get_date() -> String {
  // Simplificado para no añadir más dependencias de tiempo por ahora
  "2026-04-09"
}
