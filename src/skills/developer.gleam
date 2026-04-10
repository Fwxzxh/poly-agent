//// This module groups developer-related tools into a cohesive skill.
//// It currently includes filesystem, shell, and network tools.

import tools/fs
import tools/net
import tools/shell
import tools/utils

/// Returns a list of all tools included in the Developer skill.
pub fn get_tools() -> List(utils.Tool) {
  [
    fs.read_file_tool(),
    fs.write_file_tool(),
    fs.list_files_tool(),
    fs.grep_tool(),
    fs.find_files_tool(),
    shell.execute_command_tool(),
    net.http_get_tool(),
  ]
}
