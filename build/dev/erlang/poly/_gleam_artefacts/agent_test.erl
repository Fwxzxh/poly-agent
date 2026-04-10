-module(agent_test).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "test/agent_test.gleam").
-export([extract_text_test/0, extract_text_with_thought_test/0, extract_text_only_thought_test/0, get_function_calls_test/0, get_function_calls_empty_test/0, execute_tools_test/0, execute_tools_not_found_test/0]).

-file("test/agent_test.gleam", 9).
-spec extract_text_test() -> nil.
extract_text_test() ->
    Parts = [{text, <<"First"/utf8>>, none}, {text, <<"Second"/utf8>>, none}],
    _pipe = agent:extract_text(Parts),
    gleeunit@should:equal(_pipe, <<"First\nSecond"/utf8>>).

-file("test/agent_test.gleam", 15).
-spec extract_text_with_thought_test() -> nil.
extract_text_with_thought_test() ->
    Parts = [{thought, <<"I am thinking"/utf8>>, none},
        {text, <<"Here is the answer"/utf8>>, none}],
    _pipe = agent:extract_text(Parts),
    gleeunit@should:equal(_pipe, <<"Here is the answer"/utf8>>).

-file("test/agent_test.gleam", 24).
-spec extract_text_only_thought_test() -> nil.
extract_text_only_thought_test() ->
    Parts = [{thought, <<"Thinking really hard..."/utf8>>, none}],
    _pipe = agent:extract_text(Parts),
    gleeunit@should:equal(_pipe, <<"Thinking really hard..."/utf8>>).

-file("test/agent_test.gleam", 30).
-spec get_function_calls_test() -> nil.
get_function_calls_test() ->
    Args@1 = case gleam@json:parse(
        <<"{}"/utf8>>,
        {decoder, fun gleam@dynamic@decode:decode_dynamic/1}
    ) of
        {ok, Args} -> Args;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"agent_test"/utf8>>,
                        function => <<"get_function_calls_test"/utf8>>,
                        line => 32,
                        value => _assert_fail,
                        start => 833,
                        'end' => 894,
                        pattern_start => 844,
                        pattern_end => 852})
    end,
    Parts = [{text, <<"Some text"/utf8>>, none},
        {function_call, <<"my_tool"/utf8>>, Args@1, none}],
    Calls = agent:get_function_calls(Parts),
    case Calls of
        [{<<"my_tool"/utf8>>, _}] ->
            nil;

        _ ->
            erlang:error(#{gleam_error => panic,
                    message => <<"Expected one function call named 'my_tool'"/utf8>>,
                    file => <<?FILEPATH/utf8>>,
                    module => <<"agent_test"/utf8>>,
                    function => <<"get_function_calls_test"/utf8>>,
                    line => 40})
    end.

-file("test/agent_test.gleam", 44).
-spec get_function_calls_empty_test() -> nil.
get_function_calls_empty_test() ->
    Parts = [{text, <<"No tools here"/utf8>>, none}],
    _pipe = agent:get_function_calls(Parts),
    gleeunit@should:equal(_pipe, []).

-file("test/agent_test.gleam", 49).
-spec execute_tools_test() -> nil.
execute_tools_test() ->
    Args@1 = case gleam@json:parse(
        <<"{}"/utf8>>,
        {decoder, fun gleam@dynamic@decode:decode_dynamic/1}
    ) of
        {ok, Args} -> Args;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"agent_test"/utf8>>,
                        function => <<"execute_tools_test"/utf8>>,
                        line => 50,
                        value => _assert_fail,
                        start => 1327,
                        'end' => 1388,
                        pattern_start => 1338,
                        pattern_end => 1346})
    end,
    Calls = [{<<"test_tool"/utf8>>, Args@1}],
    Tool = begin
        _pipe = tools@utils:new(<<"test_tool"/utf8>>, <<"A test tool"/utf8>>),
        tools@utils:build_tool(
            _pipe,
            fun(_) -> gleam@json:string(<<"success"/utf8>>) end
        )
    end,
    Responses = agent:execute_tools(Calls, [Tool], fun(_) -> nil end),
    {Name@1, Response@1} = case Responses of
        [{function_response, Name, Response}] -> {Name, Response};
        _assert_fail@1 ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"agent_test"/utf8>>,
                        function => <<"execute_tools_test"/utf8>>,
                        line => 59,
                        value => _assert_fail@1,
                        start => 1612,
                        'end' => 1675,
                        pattern_start => 1623,
                        pattern_end => 1663})
    end,
    _pipe@1 = Name@1,
    gleeunit@should:equal(_pipe@1, <<"test_tool"/utf8>>),
    _pipe@2 = gleam@json:to_string(Response@1),
    gleeunit@should:equal(_pipe@2, <<"\"success\""/utf8>>).

-file("test/agent_test.gleam", 64).
-spec execute_tools_not_found_test() -> nil.
execute_tools_not_found_test() ->
    Args@1 = case gleam@json:parse(
        <<"{}"/utf8>>,
        {decoder, fun gleam@dynamic@decode:decode_dynamic/1}
    ) of
        {ok, Args} -> Args;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"agent_test"/utf8>>,
                        function => <<"execute_tools_not_found_test"/utf8>>,
                        line => 65,
                        value => _assert_fail,
                        start => 1815,
                        'end' => 1876,
                        pattern_start => 1826,
                        pattern_end => 1834})
    end,
    Calls = [{<<"unknown"/utf8>>, Args@1}],
    Responses = agent:execute_tools(Calls, [], fun(_) -> nil end),
    {Name@1, Response@1} = case Responses of
        [{function_response, Name, Response}] -> {Name, Response};
        _assert_fail@1 ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"agent_test"/utf8>>,
                        function => <<"execute_tools_not_found_test"/utf8>>,
                        line => 70,
                        value => _assert_fail@1,
                        start => 1980,
                        'end' => 2043,
                        pattern_start => 1991,
                        pattern_end => 2031})
    end,
    _pipe = Name@1,
    gleeunit@should:equal(_pipe, <<"unknown"/utf8>>),
    _pipe@1 = gleam@json:to_string(Response@1),
    gleeunit@should:equal(_pipe@1, <<"{\"error\":\"Tool not found\"}"/utf8>>).
