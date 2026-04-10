-module(dot_env@env).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/dot_env/env.gleam").
-export([set/2, get/1, get_string/1, get_or/2, get_string_or/2, get_then/2, get_int/1, get_int_or/2, get_bool/1, get_bool_or/2]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

-file("src/dot_env/env.gleam", 21).
?DOC(
    " Set an environment variable (supports both Erlang and JavaScript targets)\n"
    "\n"
    " ## Usage\n"
    "\n"
    " ```gleam\n"
    " import dot_env/env\n"
    "\n"
    " fn main() {\n"
    "   env.set(\"APP_NAME\", \"app\")\n"
    "\n"
    "   Nil\n"
    " }\n"
    " ```\n"
).
-spec set(binary(), binary()) -> {ok, nil} | {error, binary()}.
set(Key, Value) ->
    dot_env_ffi:set_env(Key, Value).

-file("src/dot_env/env.gleam", 38).
?DOC(
    " Get an environment variable (supports both Erlang and JavaScript targets)\n"
    "\n"
    " Example:\n"
    " ```gleam\n"
    " import dot_env/env\n"
    " import gleam/io\n"
    " import gleam/result\n"
    "\n"
    " env.get(\"FOO\")\n"
    " |> result.unwrap(\"NOT SET\")\n"
    " |> io.println\n"
    " ```\n"
).
-spec get(binary()) -> {ok, binary()} | {error, binary()}.
get(Key) ->
    dot_env_ffi:get_env(Key).

-file("src/dot_env/env.gleam", 58).
?DOC(
    " Get an environment variable (supports both Erlang and JavaScript targets)\n"
    "\n"
    " ## Usage\n"
    "\n"
    " ```gleam\n"
    " import dot_env/env\n"
    " import gleam/io\n"
    " import gleam/result\n"
    "\n"
    " fn main() {\n"
    "   env.get_string(\"APP_NAME\")\n"
    "   |> result.unwrap(\"app\")\n"
    "   |> io.println\n"
    " }\n"
    " ```\n"
).
-spec get_string(binary()) -> {ok, binary()} | {error, binary()}.
get_string(Key) ->
    dot_env_ffi:get_env(Key).

-file("src/dot_env/env.gleam", 62).
?DOC(" Get an environment variable or return a default value if it is not set\n").
-spec get_or(binary(), binary()) -> binary().
get_or(Key, Default) ->
    _pipe = dot_env_ffi:get_env(Key),
    gleam@result:unwrap(_pipe, Default).

-file("src/dot_env/env.gleam", 81).
?DOC(
    " Get an environment variable or return a default value if it is not set\n"
    "\n"
    " ## Usage\n"
    "\n"
    " ```gleam\n"
    " import dot_env/env\n"
    " import gleam/io\n"
    "\n"
    " fn main() {\n"
    "   let app_name = env.get_string_or(\"APP_NAME\", \"My App\")\n"
    "   io.println(app_name)\n"
    " }\n"
    " ```\n"
).
-spec get_string_or(binary(), binary()) -> binary().
get_string_or(Key, Default) ->
    _pipe = dot_env_ffi:get_env(Key),
    gleam@result:unwrap(_pipe, Default).

-file("src/dot_env/env.gleam", 100).
?DOC(
    " An alternative implementation of `get` that allows for chaining using `use` statements and for early returns.\n"
    "\n"
    " ## Usage\n"
    "\n"
    " ```gleam\n"
    " import dot_env/env\n"
    " import gleam/io\n"
    "\n"
    " fn main() {\n"
    "   use app_name <- env.get_then(\"APP_NAME\")\n"
    "   io.println(app_name)\n"
    " }\n"
    " ```\n"
).
-spec get_then(binary(), fun((binary()) -> {ok, DXK} | {error, binary()})) -> {ok,
        DXK} |
    {error, binary()}.
get_then(Key, Next) ->
    case dot_env_ffi:get_env(Key) of
        {ok, Value} ->
            Next(Value);

        {error, Err} ->
            {error, Err}
    end.

-file("src/dot_env/env.gleam", 126).
?DOC(
    " Get an environment variable as an integer (this is the same as calling `get_string` and then parsing the `Ok` value)\n"
    "\n"
    " ## Usage\n"
    "\n"
    " ```gleam\n"
    " import dot_env/env\n"
    " import gleam/io\n"
    " import gleam/result\n"
    "\n"
    " fn main() {\n"
    "   env.get_int(\"PORT\")\n"
    "   |> result.unwrap(9000)\n"
    "   |> io.println\n"
    " }\n"
    " ```\n"
).
-spec get_int(binary()) -> {ok, integer()} | {error, binary()}.
get_int(Key) ->
    get_then(Key, fun(Raw_value) -> _pipe = gleam_stdlib:parse_int(Raw_value),
            gleam@result:map_error(
                _pipe,
                fun(_) ->
                    <<<<"Failed to parse environment variable for `"/utf8,
                            Key/binary>>/binary,
                        "` as integer"/utf8>>
                end
            ) end).

-file("src/dot_env/env.gleam", 149).
?DOC(
    " Get an environment variable as an integer or return a default value if it is not set\n"
    "\n"
    " ## Usage\n"
    "\n"
    " ```gleam\n"
    " import dot_env/env\n"
    " import gleam/io\n"
    "\n"
    " fn main() {\n"
    "   let port = env.get_int_or(\"PORT\", 9000)\n"
    "   io.debug(port)\n"
    " }\n"
    " ```\n"
).
-spec get_int_or(binary(), integer()) -> integer().
get_int_or(Key, Default) ->
    _pipe = get_int(Key),
    gleam@result:unwrap(_pipe, Default).

-file("src/dot_env/env.gleam", 170).
?DOC(
    " Get an environment variable as a boolean\n"
    "\n"
    " ## Usage\n"
    "\n"
    " ```gleam\n"
    " import dot_env/env\n"
    " import gleam/io\n"
    " import gleam/result\n"
    "\n"
    " fn main() {\n"
    "   env.get_bool(\"IS_DEBUG\")\n"
    "   |> result.unwrap(False)\n"
    "   |> io.println\n"
    " }\n"
    " ```\n"
).
-spec get_bool(binary()) -> {ok, boolean()} | {error, binary()}.
get_bool(Key) ->
    get_then(Key, fun(Raw_value) -> case string:lowercase(Raw_value) of
                <<"true"/utf8>> ->
                    {ok, true};

                <<"1"/utf8>> ->
                    {ok, true};

                <<"false"/utf8>> ->
                    {ok, false};

                <<"0"/utf8>> ->
                    {ok, false};

                _ ->
                    {error,
                        <<<<"Invalid boolean value for environment variable `"/utf8,
                                Key/binary>>/binary,
                            "`. Expected one of `true`, `false`, `1`, or `0`."/utf8>>}
            end end).

-file("src/dot_env/env.gleam", 199).
?DOC(
    " Get an environment variable as a boolean or return a default value if it is not set\n"
    "\n"
    " ## Usage\n"
    "\n"
    " ```gleam\n"
    " import dot_env/env\n"
    " import gleam/io\n"
    "\n"
    " fn main() {\n"
    "   let is_debug = env.get_bool_or(\"IS_DEBUG\", True)\n"
    "   io.debug(is_debug)\n"
    " }\n"
    " ```\n"
).
-spec get_bool_or(binary(), boolean()) -> boolean().
get_bool_or(Key, Default) ->
    _pipe = get_bool(Key),
    gleam@result:unwrap(_pipe, Default).
