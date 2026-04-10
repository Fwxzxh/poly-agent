-module(common@types).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/common/types.gleam").
-export([dynamic_to_json/1]).
-export_type([message/0, part/0, tool/0, function_declaration/0, agent_event/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(
    " This module defines the core data structures used throughout the Poly framework.\n"
    " It includes types for conversations, message parts, tool declarations,\n"
    " and events emitted by the agent.\n"
).

-type message() :: {message, binary(), list(part())}.

-type part() :: {text, binary(), gleam@option:option(binary())} |
    {thought, binary(), gleam@option:option(binary())} |
    {function_call,
        binary(),
        gleam@dynamic:dynamic_(),
        gleam@option:option(binary())} |
    {function_response, binary(), gleam@json:json()}.

-type tool() :: {tool, list(function_declaration())}.

-type function_declaration() :: {function_declaration,
        binary(),
        binary(),
        gleam@option:option(gleam@json:json())}.

-type agent_event() :: {thought_event, binary()} |
    {tool_start_event, binary(), gleam@json:json()} |
    {tool_result_event, binary(), gleam@json:json()}.

-file("src/common/types.gleam", 49).
?DOC(
    " Converts a dynamic value (usually from an external API or FFI) into a JSON object.\n"
    " This is used to normalize data before sending it to the LLM or processing tool responses.\n"
).
-spec dynamic_to_json(gleam@dynamic:dynamic_()) -> gleam@json:json().
dynamic_to_json(Dyn) ->
    Encoders = [fun(D) -> _pipe = D,
            _pipe@1 = gleam@dynamic@decode:run(
                _pipe,
                {decoder, fun gleam@dynamic@decode:decode_string/1}
            ),
            gleam@result:map(_pipe@1, fun gleam@json:string/1) end, fun(D@1) ->
            _pipe@2 = D@1,
            _pipe@3 = gleam@dynamic@decode:run(
                _pipe@2,
                {decoder, fun gleam@dynamic@decode:decode_int/1}
            ),
            gleam@result:map(_pipe@3, fun gleam@json:int/1)
        end, fun(D@2) -> _pipe@4 = D@2,
            _pipe@5 = gleam@dynamic@decode:run(
                _pipe@4,
                {decoder, fun gleam@dynamic@decode:decode_float/1}
            ),
            gleam@result:map(_pipe@5, fun gleam@json:float/1) end, fun(D@3) ->
            _pipe@6 = D@3,
            _pipe@7 = gleam@dynamic@decode:run(
                _pipe@6,
                {decoder, fun gleam@dynamic@decode:decode_bool/1}
            ),
            gleam@result:map(_pipe@7, fun gleam@json:bool/1)
        end],
    Simple_value = gleam@list:find_map(
        Encoders,
        fun(Encoder) -> Encoder(Dyn) end
    ),
    case Simple_value of
        {ok, J} ->
            J;

        {error, _} ->
            case gleam@dynamic@decode:run(
                Dyn,
                gleam@dynamic@decode:list(
                    {decoder, fun gleam@dynamic@decode:decode_dynamic/1}
                )
            ) of
                {ok, L} ->
                    gleam@json:array(L, fun dynamic_to_json/1);

                {error, _} ->
                    case gleam@dynamic@decode:run(
                        Dyn,
                        gleam@dynamic@decode:optional(
                            {decoder,
                                fun gleam@dynamic@decode:decode_bit_array/1}
                        )
                    ) of
                        {ok, {some, _}} ->
                            gleam@json:null();

                        {ok, none} ->
                            gleam@json:null();

                        _ ->
                            _pipe@8 = Dyn,
                            _pipe@9 = maps:to_list(_pipe@8),
                            _pipe@10 = gleam@list:map(
                                _pipe@9,
                                fun(Pair) ->
                                    {erlang:element(1, Pair),
                                        dynamic_to_json(erlang:element(2, Pair))}
                                end
                            ),
                            gleam@json:object(_pipe@10)
                    end
            end
    end.
