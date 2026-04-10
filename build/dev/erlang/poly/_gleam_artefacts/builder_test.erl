-module(builder_test).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "test/builder_test.gleam").
-export([basic_builder_test/0, string_param_test/0, int_param_test/0, multiple_params_test/0, executor_test/0]).

-file("test/builder_test.gleam", 6).
-spec basic_builder_test() -> nil.
basic_builder_test() ->
    Tool = begin
        _pipe = tools@utils:new(<<"test_tool"/utf8>>, <<"Description"/utf8>>),
        tools@utils:build_tool(_pipe, fun(_) -> gleam@json:null() end)
    end,
    _pipe@1 = erlang:element(2, erlang:element(2, Tool)),
    gleeunit@should:equal(_pipe@1, <<"test_tool"/utf8>>),
    _pipe@2 = erlang:element(3, erlang:element(2, Tool)),
    gleeunit@should:equal(_pipe@2, <<"Description"/utf8>>),
    Params@1 = case erlang:element(4, erlang:element(2, Tool)) of
        {some, Params} -> Params;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"builder_test"/utf8>>,
                        function => <<"basic_builder_test"/utf8>>,
                        line => 14,
                        value => _assert_fail,
                        start => 339,
                        'end' => 392,
                        pattern_start => 350,
                        pattern_end => 362})
    end,
    Json_str = gleam@json:to_string(Params@1),
    _pipe@3 = Json_str,
    gleeunit@should:equal(
        _pipe@3,
        <<"{\"type\":\"object\",\"properties\":{},\"required\":[]}"/utf8>>
    ).

-file("test/builder_test.gleam", 21).
-spec string_param_test() -> nil.
string_param_test() ->
    Tool = begin
        _pipe = tools@utils:new(<<"greet"/utf8>>, <<"Greets a user"/utf8>>),
        _pipe@1 = tools@utils:with_string_param(
            _pipe,
            <<"name"/utf8>>,
            <<"The user name"/utf8>>,
            true
        ),
        tools@utils:build_tool(_pipe@1, fun(_) -> gleam@json:null() end)
    end,
    Params@1 = case erlang:element(4, erlang:element(2, Tool)) of
        {some, Params} -> Params;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"builder_test"/utf8>>,
                        function => <<"string_param_test"/utf8>>,
                        line => 27,
                        value => _assert_fail,
                        start => 729,
                        'end' => 782,
                        pattern_start => 740,
                        pattern_end => 752})
    end,
    Json_str = gleam@json:to_string(Params@1),
    _pipe@2 = Json_str,
    gleeunit@should:equal(
        _pipe@2,
        <<"{\"type\":\"object\",\"properties\":{\"name\":{\"type\":\"string\",\"description\":\"The user name\"}},\"required\":[\"name\"]}"/utf8>>
    ).

-file("test/builder_test.gleam", 36).
-spec int_param_test() -> nil.
int_param_test() ->
    Tool = begin
        _pipe = tools@utils:new(<<"add"/utf8>>, <<"Adds a number"/utf8>>),
        _pipe@1 = tools@utils:with_int_param(
            _pipe,
            <<"value"/utf8>>,
            <<"The number to add"/utf8>>,
            false
        ),
        tools@utils:build_tool(_pipe@1, fun(_) -> gleam@json:null() end)
    end,
    Params@1 = case erlang:element(4, erlang:element(2, Tool)) of
        {some, Params} -> Params;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"builder_test"/utf8>>,
                        function => <<"int_param_test"/utf8>>,
                        line => 42,
                        value => _assert_fail,
                        start => 1198,
                        'end' => 1251,
                        pattern_start => 1209,
                        pattern_end => 1221})
    end,
    Json_str = gleam@json:to_string(Params@1),
    _pipe@2 = Json_str,
    gleeunit@should:equal(
        _pipe@2,
        <<"{\"type\":\"object\",\"properties\":{\"value\":{\"type\":\"integer\",\"description\":\"The number to add\"}},\"required\":[]}"/utf8>>
    ).

-file("test/builder_test.gleam", 51).
-spec multiple_params_test() -> nil.
multiple_params_test() ->
    Tool = begin
        _pipe = tools@utils:new(<<"complex"/utf8>>, <<"A complex tool"/utf8>>),
        _pipe@1 = tools@utils:with_string_param(
            _pipe,
            <<"a"/utf8>>,
            <<"string a"/utf8>>,
            true
        ),
        _pipe@2 = tools@utils:with_int_param(
            _pipe@1,
            <<"b"/utf8>>,
            <<"int b"/utf8>>,
            false
        ),
        _pipe@3 = tools@utils:with_string_param(
            _pipe@2,
            <<"c"/utf8>>,
            <<"string c"/utf8>>,
            true
        ),
        tools@utils:build_tool(_pipe@3, fun(_) -> gleam@json:null() end)
    end,
    Params@1 = case erlang:element(4, erlang:element(2, Tool)) of
        {some, Params} -> Params;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"builder_test"/utf8>>,
                        function => <<"multiple_params_test"/utf8>>,
                        line => 59,
                        value => _assert_fail,
                        start => 1788,
                        'end' => 1841,
                        pattern_start => 1799,
                        pattern_end => 1811})
    end,
    Json_str = gleam@json:to_string(Params@1),
    _pipe@4 = Json_str,
    gleeunit@should:equal(
        _pipe@4,
        <<"{\"type\":\"object\",\"properties\":{\"a\":{\"type\":\"string\",\"description\":\"string a\"},\"b\":{\"type\":\"integer\",\"description\":\"int b\"},\"c\":{\"type\":\"string\",\"description\":\"string c\"}},\"required\":[\"a\",\"c\"]}"/utf8>>
    ).

-file("test/builder_test.gleam", 69).
-spec executor_test() -> nil.
executor_test() ->
    Tool = begin
        _pipe = tools@utils:new(<<"echo"/utf8>>, <<"Echoes input"/utf8>>),
        tools@utils:build_tool(_pipe, fun(Args) -> Args end)
    end,
    Input = gleam@json:object(
        [{<<"hello"/utf8>>, gleam@json:string(<<"world"/utf8>>)}]
    ),
    Result = (erlang:element(3, Tool))(Input),
    _pipe@1 = Result,
    gleeunit@should:equal(_pipe@1, Input).
