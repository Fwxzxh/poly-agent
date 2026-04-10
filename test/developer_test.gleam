import gleam/list
import gleeunit/should
import skills/developer

pub fn get_tools_test() {
  let tools = developer.get_tools()

  // Verify the number of tools in the developer skill
  tools |> list.length |> should.equal(7)

  // Verify that the expected tools are present by name
  let names = list.map(tools, fn(t) { t.declaration.name })

  names |> list.contains("read_file") |> should.be_true
  names |> list.contains("write_file") |> should.be_true
  names |> list.contains("list_files") |> should.be_true
  names |> list.contains("grep") |> should.be_true
  names |> list.contains("find_files") |> should.be_true
  names |> list.contains("execute_command") |> should.be_true
  names |> list.contains("http_get") |> should.be_true
}
