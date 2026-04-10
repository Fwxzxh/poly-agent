-module(skills@developer).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/skills/developer.gleam").
-export([get_tools/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(
    " This module groups developer-related tools into a cohesive skill.\n"
    " It currently includes filesystem, shell, and network tools.\n"
).

-file("src/skills/developer.gleam", 10).
?DOC(" Returns a list of all tools included in the Developer skill.\n").
-spec get_tools() -> list(tools@utils:tool()).
get_tools() ->
    [tools@fs:read_file_tool(),
        tools@fs:list_files_tool(),
        tools@shell:execute_command_tool(),
        tools@net:http_get_tool()].
