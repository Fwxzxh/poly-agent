-module(tools@system).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/tools/system.gleam").
-export([get_info/0, format_as_context/1]).
-export_type([system_info/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(
    " This module provides system-level information for the agent.\n"
    " It retrieves environment details to give the AI context about the host.\n"
).

-type system_info() :: {system_info,
        binary(),
        binary(),
        binary(),
        binary(),
        binary()}.

-file("src/tools/system.gleam", 19).
?DOC(" Gathers information from the operating system and current environment.\n").
-spec get_info() -> system_info().
get_info() ->
    {Os_type, Os_version, Arch, User} = poly_ffi:get_system_info(),
    Cwd = case simplifile:current_directory() of
        {ok, Path} ->
            Path;

        {error, _} ->
            <<"unknown"/utf8>>
    end,
    {system_info,
        gleam@string:inspect(Os_type),
        gleam@string:inspect(Os_version),
        gleam@string:inspect(Arch),
        gleam@string:inspect(User),
        Cwd}.

-file("src/tools/system.gleam", 48).
-spec get_date() -> binary().
get_date() ->
    <<"2026-04-09"/utf8>>.

-file("src/tools/system.gleam", 36).
?DOC(" Formats the gathered system information as a text block for the system prompt.\n").
-spec format_as_context(system_info()) -> binary().
format_as_context(Info) ->
    <<<<<<<<<<<<<<<<<<<<<<"System Context:
- OS: "/utf8,
                                                (erlang:element(2, Info))/binary>>/binary,
                                            " ("/utf8>>/binary,
                                        (erlang:element(3, Info))/binary>>/binary,
                                    ")
- Architecture: "/utf8>>/binary,
                                (erlang:element(4, Info))/binary>>/binary,
                            "
- User: "/utf8>>/binary,
                        (erlang:element(5, Info))/binary>>/binary,
                    "
- Working Directory: "/utf8>>/binary,
                (erlang:element(6, Info))/binary>>/binary,
            "
- Date: "/utf8>>/binary,
        (get_date())/binary>>.
