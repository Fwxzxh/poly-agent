-module(tools@fs).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/tools/fs.gleam").
-export([read_file_tool/0, list_files_tool/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(" This module contains filesystem-related tools for the agent.\n").

-file("src/tools/fs.gleam", 23).
-spec read_file_executor(gleam@json:json()) -> gleam@json:json().
read_file_executor(Args) ->
    Decoder = begin
        gleam@dynamic@decode:field(
            <<"path"/utf8>>,
            {decoder, fun gleam@dynamic@decode:decode_string/1},
            fun(Path) -> gleam@dynamic@decode:success(Path) end
        )
    end,
    case gleam@dynamic@decode:run(poly_ffi:identity(Args), Decoder) of
        {ok, Path@1} ->
            case simplifile:read(Path@1) of
                {ok, Content} ->
                    gleam@json:object(
                        [{<<"content"/utf8>>, gleam@json:string(Content)}]
                    );

                {error, Err} ->
                    gleam@json:object(
                        [{<<"error"/utf8>>,
                                gleam@json:string(
                                    <<"Could not read file: "/utf8,
                                        (gleam@string:inspect(Err))/binary>>
                                )}]
                    )
            end;

        {error, _} ->
            gleam@json:object(
                [{<<"error"/utf8>>,
                        gleam@json:string(
                            <<"Missing or invalid 'path' argument"/utf8>>
                        )}]
            )
    end.

-file("src/tools/fs.gleam", 10).
?DOC(" Returns the \"read_file\" tool.\n").
-spec read_file_tool() -> tools@utils:tool().
read_file_tool() ->
    _pipe = tools@utils:new(
        <<"read_file"/utf8>>,
        <<"Reads the content of a file from the local filesystem."/utf8>>
    ),
    _pipe@1 = tools@utils:with_string_param(
        _pipe,
        <<"path"/utf8>>,
        <<"The absolute or relative path to the file"/utf8>>,
        true
    ),
    tools@utils:build_tool(_pipe@1, fun read_file_executor/1).

-file("src/tools/fs.gleam", 60).
-spec list_files_executor(gleam@json:json()) -> gleam@json:json().
list_files_executor(Args) ->
    Decoder = begin
        gleam@dynamic@decode:field(
            <<"directory"/utf8>>,
            {decoder, fun gleam@dynamic@decode:decode_string/1},
            fun(Directory) -> gleam@dynamic@decode:success(Directory) end
        )
    end,
    case gleam@dynamic@decode:run(poly_ffi:identity(Args), Decoder) of
        {ok, Dir} ->
            case simplifile_erl:read_directory(Dir) of
                {ok, Files} ->
                    gleam@json:object(
                        [{<<"files"/utf8>>,
                                gleam@json:array(Files, fun gleam@json:string/1)}]
                    );

                {error, Err} ->
                    gleam@json:object(
                        [{<<"error"/utf8>>,
                                gleam@json:string(
                                    <<"Could not list directory: "/utf8,
                                        (gleam@string:inspect(Err))/binary>>
                                )}]
                    )
            end;

        {error, _} ->
            gleam@json:object(
                [{<<"error"/utf8>>,
                        gleam@json:string(
                            <<"Missing or invalid 'directory' argument"/utf8>>
                        )}]
            )
    end.

-file("src/tools/fs.gleam", 50).
?DOC(" Returns the \"list_files\" tool.\n").
-spec list_files_tool() -> tools@utils:tool().
list_files_tool() ->
    _pipe = tools@utils:new(
        <<"list_files"/utf8>>,
        <<"Lists all files in a given directory."/utf8>>
    ),
    _pipe@1 = tools@utils:with_string_param(
        _pipe,
        <<"directory"/utf8>>,
        <<"The directory path to list files from"/utf8>>,
        true
    ),
    tools@utils:build_tool(_pipe@1, fun list_files_executor/1).
