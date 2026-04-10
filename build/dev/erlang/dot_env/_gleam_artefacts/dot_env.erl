-module(dot_env).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/dot_env.gleam").
-export([set_debug/2, set_capitalize/2, set_ignore_missing_file/2, set_path/2, path/1, new/0, new_with_path/1, load_with_opts/1, load/1, load_default/0]).
-export_type([opts/0, dot_env/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

-type opts() :: {opts, binary(), boolean(), boolean(), boolean()} | default.

-opaque dot_env() :: {dot_env, binary(), boolean(), boolean(), boolean()}.

-file("src/dot_env.gleam", 48).
?DOC(" Set whether to print debug information in the current DotEnv instance\n").
-spec set_debug(dot_env(), boolean()) -> dot_env().
set_debug(Instance, Debug) ->
    {dot_env,
        erlang:element(2, Instance),
        Debug,
        erlang:element(4, Instance),
        erlang:element(5, Instance)}.

-file("src/dot_env.gleam", 53).
?DOC(" Set whether to capitalize all keys in the current DotEnv instance\n").
-spec set_capitalize(dot_env(), boolean()) -> dot_env().
set_capitalize(Instance, Capitalize) ->
    {dot_env,
        erlang:element(2, Instance),
        erlang:element(3, Instance),
        Capitalize,
        erlang:element(5, Instance)}.

-file("src/dot_env.gleam", 58).
?DOC(" Set whether to ignore missing file errors in the current DotEnv instance\n").
-spec set_ignore_missing_file(dot_env(), boolean()) -> dot_env().
set_ignore_missing_file(Instance, Ignore_missing_file) ->
    {dot_env,
        erlang:element(2, Instance),
        erlang:element(3, Instance),
        erlang:element(4, Instance),
        Ignore_missing_file}.

-file("src/dot_env.gleam", 66).
?DOC(" Set the path to the .env file in the current DotEnv instance\n").
-spec set_path(dot_env(), binary()) -> dot_env().
set_path(Instance, Path) ->
    {dot_env,
        Path,
        erlang:element(3, Instance),
        erlang:element(4, Instance),
        erlang:element(5, Instance)}.

-file("src/dot_env.gleam", 71).
?DOC(" Get the path to the .env file in the current DotEnv instance\n").
-spec path(dot_env()) -> binary().
path(Instance) ->
    erlang:element(2, Instance).

-file("src/dot_env.gleam", 157).
-spec handle_file_result({ok, binary()} | {error, binary()}, boolean()) -> {ok,
        binary()} |
    {error, binary()}.
handle_file_result(Res, Ignore_error) ->
    gleam@bool:guard(
        gleam@result:is_error(Res) andalso Ignore_error,
        {ok, <<""/utf8>>},
        fun() -> Res end
    ).

-file("src/dot_env.gleam", 165).
-spec set_env(dot_env(), {binary(), binary()}) -> {ok, nil} | {error, binary()}.
set_env(Config, Pair) ->
    Key = begin
        gleam@bool:guard(
            not erlang:element(4, Config),
            erlang:element(1, Pair),
            fun() -> string:uppercase(erlang:element(1, Pair)) end
        )
    end,
    _pipe = Key,
    dot_env_ffi:set_env(_pipe, erlang:element(2, Pair)).

-file("src/dot_env.gleam", 175).
-spec recursively_set_environment_variables(
    dot_env(),
    list({binary(), binary()})
) -> {ok, nil} | {error, binary()}.
recursively_set_environment_variables(Config, Kv_pairs) ->
    case Kv_pairs of
        [] ->
            {ok, nil};

        [Pair] ->
            set_env(Config, Pair);

        [Pair@1 | Rest] ->
            gleam@result:'try'(
                set_env(Config, Pair@1),
                fun(_) ->
                    recursively_set_environment_variables(Config, Rest)
                end
            )
    end.

-file("src/dot_env.gleam", 189).
-spec read_file(dot_env()) -> {ok, binary()} | {error, binary()}.
read_file(Dotenv) ->
    gleam@result:'try'(
        begin
            _pipe = simplifile_erl:is_file(erlang:element(2, Dotenv)),
            gleam@result:map_error(
                _pipe,
                fun(_) ->
                    <<"Failed to access file, ensure the file exists and is a readable file"/utf8>>
                end
            )
        end,
        fun(Is_file) ->
            gleam@bool:guard(
                not Is_file,
                {error,
                    <<<<"Specified file at `"/utf8,
                            (erlang:element(2, Dotenv))/binary>>/binary,
                        "` does not exist"/utf8>>},
                fun() ->
                    gleam@result:'try'(
                        begin
                            _pipe@1 = simplifile:read(erlang:element(2, Dotenv)),
                            gleam@result:map_error(
                                _pipe@1,
                                fun(_) ->
                                    <<<<"Unable to read file at `"/utf8,
                                            (erlang:element(2, Dotenv))/binary>>/binary,
                                        "`, ensure the file exists and is readable"/utf8>>
                                end
                            )
                        end,
                        fun(Contents) -> {ok, Contents} end
                    )
                end
            )
        end
    ).

-file("src/dot_env.gleam", 145).
-spec load_and_return_error(dot_env()) -> {ok, nil} | {error, binary()}.
load_and_return_error(Dotenv) ->
    gleam@result:'try'(
        begin
            _pipe = read_file(Dotenv),
            handle_file_result(_pipe, erlang:element(5, Dotenv))
        end,
        fun(Content) ->
            gleam@result:'try'(
                dot_env@internal@parser:parse(Content),
                fun(Kv_pairs) -> _pipe@1 = Dotenv,
                    recursively_set_environment_variables(_pipe@1, Kv_pairs) end
            )
        end
    ).

-file("src/dot_env.gleam", 38).
?DOC(" Create a default DotEnv instance. This is designed to use used as the starting point for using any of the builder methods\n").
-spec new() -> dot_env().
new() ->
    {dot_env, <<".env"/utf8>>, true, true, true}.

-file("src/dot_env.gleam", 43).
?DOC(" Create a new DotEnv instance with the specified path\n").
-spec new_with_path(binary()) -> dot_env().
new_with_path(Path) ->
    {dot_env,
        Path,
        erlang:element(3, {dot_env, <<".env"/utf8>>, true, true, true}),
        erlang:element(4, {dot_env, <<".env"/utf8>>, true, true, true}),
        erlang:element(5, {dot_env, <<".env"/utf8>>, true, true, true})}.

-file("src/dot_env.gleam", 127).
?DOC(
    " Load the .env file at the specified path and set the environment variables\n"
    "\n"
    " Debug information and key capitalization can be customized\n"
    "\n"
    " # Example\n"
    "\n"
    " ```gleam\n"
    " import dot_env\n"
    "\n"
    " pub fn main() {\n"
    "   dot_env.load_with_opts(dot_env.Opts(path: \"src/.env\", debug: False, capitalize: False))\n"
    " }\n"
    " ```\n"
).
-spec load_with_opts(opts()) -> nil.
load_with_opts(Opts) ->
    Dotenv = case Opts of
        {opts, Path, Debug, Capitalize, Ignore_missing_file} ->
            {dot_env, Path, Debug, Capitalize, Ignore_missing_file};

        default ->
            {dot_env, <<".env"/utf8>>, true, true, true}
    end,
    State = begin
        _pipe = Dotenv,
        load_and_return_error(_pipe)
    end,
    case State of
        {ok, _} ->
            nil;

        {error, Msg} ->
            gleam@bool:guard(
                not erlang:element(3, Dotenv),
                nil,
                fun() -> gleam_stdlib:println_error(Msg) end
            )
    end.

-file("src/dot_env.gleam", 88).
?DOC(
    " Load the .env file using the current DotEnv instance and set the environment variables\n"
    "\n"
    " # Example\n"
    "\n"
    " ```gleam\n"
    " import dot_env as dot\n"
    "\n"
    " pub fn main() {\n"
    "   dot.new()\n"
    "   |> dot.set_path(\"src/.env\")\n"
    "   |> dot.set_debug(False)\n"
    "   |> dot.load\n"
    " }\n"
).
-spec load(dot_env()) -> nil.
load(Dotenv) ->
    load_with_opts(
        {opts,
            erlang:element(2, Dotenv),
            erlang:element(3, Dotenv),
            erlang:element(4, Dotenv),
            erlang:element(5, Dotenv)}
    ).

-file("src/dot_env.gleam", 110).
?DOC(
    " Load the .env file at the default path (.env) and set the environment variables\n"
    "\n"
    " Debug information will be printed to the console if something goes wrong and all keys will be capitalized\n"
    "\n"
    " # Example\n"
    "\n"
    " ```gleam\n"
    " import dot_env\n"
    "\n"
    " pub fn main() {\n"
    "   dot_env.load_default()\n"
    " }\n"
    " ```\n"
).
-spec load_default() -> nil.
load_default() ->
    load_with_opts(default).
