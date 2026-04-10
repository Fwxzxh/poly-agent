import gleam/string
import gleeunit/should
import tools/system

pub fn get_info_test() {
  let info = system.get_info()

  // Basic validation that info fields are not empty
  info.os_type |> string.is_empty |> should.be_false
  info.architecture |> string.is_empty |> should.be_false
  info.current_user |> string.is_empty |> should.be_false
  info.working_directory |> string.is_empty |> should.be_false
}

pub fn format_as_context_test() {
  let info =
    system.SystemInfo(
      os_type: "unix",
      os_version: "1.0",
      architecture: "arm64",
      current_user: "tester",
      working_directory: "/tmp",
    )

  let context = system.format_as_context(info)

  context |> string.contains("System Context:") |> should.be_true
  context |> string.contains("OS: unix") |> should.be_true
  context |> string.contains("Architecture: arm64") |> should.be_true
  context |> string.contains("User: tester") |> should.be_true
  context |> string.contains("Working Directory: /tmp") |> should.be_true
}
