-module(types_test).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "test/types_test.gleam").
-export([string_to_json_test/0, int_to_json_test/0, float_to_json_test/0, bool_to_json_test/0, list_to_json_test/0, object_to_json_test/0, nested_to_json_test/0, null_to_json_test/0, agent_event_types_test/0]).

-file("test/types_test.gleam", 6).
-spec string_to_json_test() -> nil.
string_to_json_test() ->
    Dyn@1 = case gleam@json:parse(
        <<"\"hello\""/utf8>>,
        {decoder, fun gleam@dynamic@decode:decode_dynamic/1}
    ) of
        {ok, Dyn} -> Dyn;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"types_test"/utf8>>,
                        function => <<"string_to_json_test"/utf8>>,
                        line => 7,
                        value => _assert_fail,
                        start => 123,
                        'end' => 183,
                        pattern_start => 134,
                        pattern_end => 141})
    end,
    _pipe = common@types:dynamic_to_json(Dyn@1),
    _pipe@1 = gleam@json:to_string(_pipe),
    gleeunit@should:equal(_pipe@1, <<"\"hello\""/utf8>>).

-file("test/types_test.gleam", 11).
-spec int_to_json_test() -> nil.
int_to_json_test() ->
    Dyn@1 = case gleam@json:parse(
        <<"123"/utf8>>,
        {decoder, fun gleam@dynamic@decode:decode_dynamic/1}
    ) of
        {ok, Dyn} -> Dyn;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"types_test"/utf8>>,
                        function => <<"int_to_json_test"/utf8>>,
                        line => 12,
                        value => _assert_fail,
                        start => 293,
                        'end' => 347,
                        pattern_start => 304,
                        pattern_end => 311})
    end,
    _pipe = common@types:dynamic_to_json(Dyn@1),
    _pipe@1 = gleam@json:to_string(_pipe),
    gleeunit@should:equal(_pipe@1, <<"123"/utf8>>).

-file("test/types_test.gleam", 16).
-spec float_to_json_test() -> nil.
float_to_json_test() ->
    Dyn@1 = case gleam@json:parse(
        <<"1.25"/utf8>>,
        {decoder, fun gleam@dynamic@decode:decode_dynamic/1}
    ) of
        {ok, Dyn} -> Dyn;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"types_test"/utf8>>,
                        function => <<"float_to_json_test"/utf8>>,
                        line => 17,
                        value => _assert_fail,
                        start => 453,
                        'end' => 508,
                        pattern_start => 464,
                        pattern_end => 471})
    end,
    _pipe = common@types:dynamic_to_json(Dyn@1),
    _pipe@1 = gleam@json:to_string(_pipe),
    gleeunit@should:equal(_pipe@1, <<"1.25"/utf8>>).

-file("test/types_test.gleam", 21).
-spec bool_to_json_test() -> nil.
bool_to_json_test() ->
    Dyn@1 = case gleam@json:parse(
        <<"true"/utf8>>,
        {decoder, fun gleam@dynamic@decode:decode_dynamic/1}
    ) of
        {ok, Dyn} -> Dyn;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"types_test"/utf8>>,
                        function => <<"bool_to_json_test"/utf8>>,
                        line => 22,
                        value => _assert_fail,
                        start => 614,
                        'end' => 669,
                        pattern_start => 625,
                        pattern_end => 632})
    end,
    _pipe = common@types:dynamic_to_json(Dyn@1),
    _pipe@1 = gleam@json:to_string(_pipe),
    gleeunit@should:equal(_pipe@1, <<"true"/utf8>>).

-file("test/types_test.gleam", 26).
-spec list_to_json_test() -> nil.
list_to_json_test() ->
    Dyn@1 = case gleam@json:parse(
        <<"[1, \"two\", true]"/utf8>>,
        {decoder, fun gleam@dynamic@decode:decode_dynamic/1}
    ) of
        {ok, Dyn} -> Dyn;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"types_test"/utf8>>,
                        function => <<"list_to_json_test"/utf8>>,
                        line => 27,
                        value => _assert_fail,
                        start => 775,
                        'end' => 844,
                        pattern_start => 786,
                        pattern_end => 793})
    end,
    _pipe = common@types:dynamic_to_json(Dyn@1),
    _pipe@1 = gleam@json:to_string(_pipe),
    gleeunit@should:equal(_pipe@1, <<"[1,\"two\",true]"/utf8>>).

-file("test/types_test.gleam", 33).
-spec object_to_json_test() -> nil.
object_to_json_test() ->
    Dyn@1 = case gleam@json:parse(
        <<"{\"a\": 1, \"b\": \"text\"}"/utf8>>,
        {decoder, fun gleam@dynamic@decode:decode_dynamic/1}
    ) of
        {ok, Dyn} -> Dyn;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"types_test"/utf8>>,
                        function => <<"object_to_json_test"/utf8>>,
                        line => 34,
                        value => _assert_fail,
                        start => 968,
                        'end' => 1046,
                        pattern_start => 979,
                        pattern_end => 986})
    end,
    Json_str = begin
        _pipe = common@types:dynamic_to_json(Dyn@1),
        gleam@json:to_string(_pipe)
    end,
    _pipe@1 = Json_str,
    gleeunit@should:equal(_pipe@1, <<"{\"a\":1,\"b\":\"text\"}"/utf8>>).

-file("test/types_test.gleam", 40).
-spec nested_to_json_test() -> nil.
nested_to_json_test() ->
    Input = <<"{\"inner\":[1,2],\"val\":{\"ok\":true}}"/utf8>>,
    Dyn@1 = case gleam@json:parse(
        Input,
        {decoder, fun gleam@dynamic@decode:decode_dynamic/1}
    ) of
        {ok, Dyn} -> Dyn;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"types_test"/utf8>>,
                        function => <<"nested_to_json_test"/utf8>>,
                        line => 42,
                        value => _assert_fail,
                        start => 1330,
                        'end' => 1384,
                        pattern_start => 1341,
                        pattern_end => 1348})
    end,
    Json_str = begin
        _pipe = common@types:dynamic_to_json(Dyn@1),
        gleam@json:to_string(_pipe)
    end,
    _pipe@1 = Json_str,
    gleeunit@should:equal(_pipe@1, Input).

-file("test/types_test.gleam", 47).
-spec null_to_json_test() -> nil.
null_to_json_test() ->
    Dyn@1 = case gleam@json:parse(
        <<"null"/utf8>>,
        {decoder, fun gleam@dynamic@decode:decode_dynamic/1}
    ) of
        {ok, Dyn} -> Dyn;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"types_test"/utf8>>,
                        function => <<"null_to_json_test"/utf8>>,
                        line => 48,
                        value => _assert_fail,
                        start => 1515,
                        'end' => 1570,
                        pattern_start => 1526,
                        pattern_end => 1533})
    end,
    _pipe = common@types:dynamic_to_json(Dyn@1),
    _pipe@1 = gleam@json:to_string(_pipe),
    gleeunit@should:equal(_pipe@1, <<"null"/utf8>>).

-file("test/types_test.gleam", 52).
-spec agent_event_types_test() -> nil.
agent_event_types_test() ->
    _ = {thought_event, <<"thinking"/utf8>>},
    _ = {tool_start_event, <<"tool"/utf8>>, gleam@json:object([])},
    _ = {tool_result_event, <<"tool"/utf8>>, gleam@json:string(<<"done"/utf8>>)},
    _pipe = true,
    gleeunit@should:be_true(_pipe).
