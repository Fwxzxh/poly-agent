-module(tools@shell).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/tools/shell.gleam").
-export([execute_command_tool/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(" This module contains tools for executing shell commands.\n").

-file("src/tools/shell.gleam", 21).
-spec execute_command_executor(gleam@json:json()) -> gleam@json:json().
execute_command_executor(Args) ->
    Decoder = begin
        gleam@dynamic@decode:field(
            <<"command"/utf8>>,
            {decoder, fun gleam@dynamic@decode:decode_string/1},
            fun(Command) -> gleam@dynamic@decode:success(Command) end
        )
    end,
    case gleam@dynamic@decode:run(poly_ffi:identity(Args), Decoder) of
        {ok, Command@1} ->
            case poly_ffi:run_command(Command@1) of
                {0, Stdout} ->
                    gleam@json:object(
                        [{<<"status"/utf8>>, gleam@json:int(0)},
                            {<<"output"/utf8>>, gleam@json:string(Stdout)}]
                    );

                {Code, Output} ->
                    gleam@json:object(
                        [{<<"status"/utf8>>, gleam@json:int(Code)},
                            {<<"error"/utf8>>, gleam@json:string(Output)}]
                    )
            end;

        {error, _} ->
            gleam@json:object(
                [{<<"error"/utf8>>,
                        gleam@json:string(
                            <<"Missing or invalid 'command' argument"/utf8>>
                        )}]
            )
    end.

-file("src/tools/shell.gleam", 8).
?DOC(" Returns the \"execute_command\" tool.\n").
-spec execute_command_tool() -> tools@utils:tool().
execute_command_tool() ->
    _pipe = tools@utils:new(
        <<"execute_command"/utf8>>,
        <<"Executes a shell command on the local system and returns the output."/utf8>>
    ),
    _pipe@1 = tools@utils:with_string_param(
        _pipe,
        <<"command"/utf8>>,
        <<"The shell command to execute (e.g., 'ls -la' or 'grep')"/utf8>>,
        true
    ),
    tools@utils:build_tool(_pipe@1, fun execute_command_executor/1).
