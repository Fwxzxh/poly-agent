-module(providers@interface).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/providers/interface.gleam").
-export_type([provider/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(
    " This module defines the common interface for AI providers.\n"
    " Any new LLM integration (like OpenAI, Claude, or local models) must\n"
    " adhere to the `Provider` type defined here.\n"
).

-type provider() :: {provider,
        binary(),
        fun((list(common@types:message()), gleam@option:option(binary()), binary(), binary(), list(common@types:function_declaration()), boolean()) -> {ok,
                list(common@types:part())} |
            {error, nil})}.


