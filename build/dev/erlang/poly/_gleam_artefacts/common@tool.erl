-module(common@tool).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/common/tool.gleam").
-export([new/2, with_string_param/4, with_int_param/4, build_tool/2]).
-export_type([tool/0, tool_builder/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

-type tool() :: {tool,
        common@types:function_declaration(),
        fun((gleam@json:json()) -> gleam@json:json())}.

-type tool_builder() :: {tool_builder,
        binary(),
        binary(),
        list({binary(), gleam@json:json()}),
        list(binary())}.

-file("src/common/tool.gleam", 26).
?DOC(" Start building a new tool.\n").
-spec new(binary(), binary()) -> tool_builder().
new(Name, Description) ->
    {tool_builder, Name, Description, [], []}.

-file("src/common/tool.gleam", 36).
?DOC(" Adds a string parameter to a tool''s declaration.\n").
-spec with_string_param(tool_builder(), binary(), binary(), boolean()) -> tool_builder().
with_string_param(Builder, Name, Description, Required) ->
    Param = gleam@json:object(
        [{<<"type"/utf8>>, gleam@json:string(<<"string"/utf8>>)},
            {<<"description"/utf8>>, gleam@json:string(Description)}]
    ),
    {tool_builder,
        erlang:element(2, Builder),
        erlang:element(3, Builder),
        lists:append(erlang:element(4, Builder), [{Name, Param}]),
        case Required of
            true ->
                lists:append(erlang:element(5, Builder), [Name]);

            false ->
                erlang:element(5, Builder)
        end}.

-file("src/common/tool.gleam", 58).
?DOC(" Adds an integer parameter to a tool''s declaration.\n").
-spec with_int_param(tool_builder(), binary(), binary(), boolean()) -> tool_builder().
with_int_param(Builder, Name, Description, Required) ->
    Param = gleam@json:object(
        [{<<"type"/utf8>>, gleam@json:string(<<"integer"/utf8>>)},
            {<<"description"/utf8>>, gleam@json:string(Description)}]
    ),
    {tool_builder,
        erlang:element(2, Builder),
        erlang:element(3, Builder),
        lists:append(erlang:element(4, Builder), [{Name, Param}]),
        case Required of
            true ->
                lists:append(erlang:element(5, Builder), [Name]);

            false ->
                erlang:element(5, Builder)
        end}.

-file("src/common/tool.gleam", 80).
?DOC(" Completes the tool building by providing an executor.\n").
-spec build_tool(tool_builder(), fun((gleam@json:json()) -> gleam@json:json())) -> tool().
build_tool(Builder, Executor) ->
    Parameters = gleam@json:object(
        [{<<"type"/utf8>>, gleam@json:string(<<"object"/utf8>>)},
            {<<"properties"/utf8>>,
                gleam@json:object(erlang:element(4, Builder))},
            {<<"required"/utf8>>,
                gleam@json:array(
                    erlang:element(5, Builder),
                    fun gleam@json:string/1
                )}]
    ),
    Declaration = {function_declaration,
        erlang:element(2, Builder),
        erlang:element(3, Builder),
        {some, Parameters}},
    {tool, Declaration, Executor}.
