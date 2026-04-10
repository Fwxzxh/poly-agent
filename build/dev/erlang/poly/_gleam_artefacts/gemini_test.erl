-module(gemini_test).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "test/gemini_test.gleam").
-export([message_with_text_to_json_test/0, build_request_body_with_system_instruction_test/0, message_with_function_call_to_json_test/0, tool_to_json_test/0, decode_text_response_test/0, decode_function_call_response_test/0, decode_thought_response_test/0, decode_empty_candidates_response_test/0, decode_malformed_json_test/0, message_with_function_response_to_json_test/0, build_request_body_minimal_test/0]).

-file("test/gemini_test.gleam", 9).
-spec message_with_text_to_json_test() -> nil.
message_with_text_to_json_test() ->
    Msg = {message, <<"user"/utf8>>, [{text, <<"Hello"/utf8>>, none}]},
    Json_str = begin
        _pipe = providers@gemini:message_to_json(Msg),
        gleam@json:to_string(_pipe)
    end,
    _pipe@1 = Json_str,
    _pipe@2 = gleam_stdlib:contains_string(
        _pipe@1,
        <<"\"role\":\"user\""/utf8>>
    ),
    gleeunit@should:be_true(_pipe@2),
    _pipe@3 = Json_str,
    _pipe@4 = gleam_stdlib:contains_string(
        _pipe@3,
        <<"\"text\":\"Hello\""/utf8>>
    ),
    gleeunit@should:be_true(_pipe@4).

-file("test/gemini_test.gleam", 17).
-spec build_request_body_with_system_instruction_test() -> nil.
build_request_body_with_system_instruction_test() ->
    History = [{message, <<"user"/utf8>>, [{text, <<"Hello"/utf8>>, none}]}],
    Body = providers@gemini:build_request_body(
        History,
        {some, <<"You are a bot"/utf8>>},
        []
    ),
    _pipe = Body,
    _pipe@1 = gleam_stdlib:contains_string(
        _pipe,
        <<"\"system_instruction\""/utf8>>
    ),
    gleeunit@should:be_true(_pipe@1),
    _pipe@2 = Body,
    _pipe@3 = gleam_stdlib:contains_string(
        _pipe@2,
        <<"\"text\":\"You are a bot\""/utf8>>
    ),
    gleeunit@should:be_true(_pipe@3).

-file("test/gemini_test.gleam", 27).
-spec message_with_function_call_to_json_test() -> nil.
message_with_function_call_to_json_test() ->
    Args@1 = case gleam@json:parse(
        <<"{\"command\":\"ls\"}"/utf8>>,
        {decoder, fun gleam@dynamic@decode:decode_dynamic/1}
    ) of
        {ok, Args} -> Args;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"gemini_test"/utf8>>,
                        function => <<"message_with_function_call_to_json_test"/utf8>>,
                        line => 28,
                        value => _assert_fail,
                        start => 917,
                        'end' => 1000,
                        pattern_start => 928,
                        pattern_end => 936})
    end,
    Msg = {message,
        <<"model"/utf8>>,
        [{function_call, <<"execute"/utf8>>, Args@1, {some, <<"sig123"/utf8>>}}]},
    Json_str = begin
        _pipe = providers@gemini:message_to_json(Msg),
        gleam@json:to_string(_pipe)
    end,
    _pipe@1 = Json_str,
    _pipe@2 = gleam_stdlib:contains_string(
        _pipe@1,
        <<"\"thoughtSignature\":\"sig123\""/utf8>>
    ),
    gleeunit@should:be_true(_pipe@2),
    _pipe@3 = Json_str,
    _pipe@4 = gleam_stdlib:contains_string(
        _pipe@3,
        <<"\"args\":{\"command\":\"ls\"}"/utf8>>
    ),
    gleeunit@should:be_true(_pipe@4).

-file("test/gemini_test.gleam", 44).
-spec tool_to_json_test() -> nil.
tool_to_json_test() ->
    Fd = {function_declaration,
        <<"get_weather"/utf8>>,
        <<"Gets the weather"/utf8>>,
        {some,
            gleam@json:object(
                [{<<"type"/utf8>>, gleam@json:string(<<"object"/utf8>>)},
                    {<<"properties"/utf8>>,
                        gleam@json:object(
                            [{<<"location"/utf8>>,
                                    gleam@json:object(
                                        [{<<"type"/utf8>>,
                                                gleam@json:string(
                                                    <<"string"/utf8>>
                                                )}]
                                    )}]
                        )}]
            )}},
    Tool = {tool, [Fd]},
    Json_str = begin
        _pipe = providers@gemini:tool_to_json(Tool),
        gleam@json:to_string(_pipe)
    end,
    _pipe@1 = Json_str,
    _pipe@2 = gleam_stdlib:contains_string(
        _pipe@1,
        <<"\"name\":\"get_weather\""/utf8>>
    ),
    gleeunit@should:be_true(_pipe@2),
    _pipe@3 = Json_str,
    _pipe@4 = gleam_stdlib:contains_string(
        _pipe@3,
        <<"\"type\":\"object\""/utf8>>
    ),
    gleeunit@should:be_true(_pipe@4).

-file("test/gemini_test.gleam", 69).
-spec decode_text_response_test() -> nil.
decode_text_response_test() ->
    Raw_json = <<"
    {
      \"candidates\": [
        {
          \"content\": {
            \"role\": \"model\",
            \"parts\": [
              {
                \"text\": \"Hello there!\",
                \"thoughtSignature\": \"sig_text\"
              }
            ]
          }
        }
      ]
    }
  "/utf8>>,
    Result = providers@gemini:decode_response(Raw_json),
    _pipe = Result,
    gleeunit@should:be_ok(_pipe),
    {Text@1, Sig@1} = case Result of
        {ok, [{text, Text, {some, Sig}}]} -> {Text, Sig};
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"gemini_test"/utf8>>,
                        function => <<"decode_text_response_test"/utf8>>,
                        line => 92,
                        value => _assert_fail,
                        start => 2514,
                        'end' => 2567,
                        pattern_start => 2525,
                        pattern_end => 2558})
    end,
    _pipe@1 = Text@1,
    gleeunit@should:equal(_pipe@1, <<"Hello there!"/utf8>>),
    _pipe@2 = Sig@1,
    gleeunit@should:equal(_pipe@2, <<"sig_text"/utf8>>).

-file("test/gemini_test.gleam", 97).
-spec decode_function_call_response_test() -> nil.
decode_function_call_response_test() ->
    Raw_json = <<"
    {
      \"candidates\": [
        {
          \"content\": {
            \"parts\": [
              {
                \"functionCall\": {
                  \"name\": \"get_time\",
                  \"args\": {
                    \"format\": \"24h\"
                  }
                },
                \"thoughtSignature\": \"sig_fc\"
              }
            ]
          }
        }
      ]
    }
  "/utf8>>,
    Result = providers@gemini:decode_response(Raw_json),
    _pipe = Result,
    gleeunit@should:be_ok(_pipe),
    {Name@1, Sig@1} = case Result of
        {ok, [{function_call, Name, _, {some, Sig}}]} -> {Name, Sig};
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"gemini_test"/utf8>>,
                        function => <<"decode_function_call_response_test"/utf8>>,
                        line => 124,
                        value => _assert_fail,
                        start => 3202,
                        'end' => 3270,
                        pattern_start => 3213,
                        pattern_end => 3261})
    end,
    _pipe@1 = Name@1,
    gleeunit@should:equal(_pipe@1, <<"get_time"/utf8>>),
    _pipe@2 = Sig@1,
    gleeunit@should:equal(_pipe@2, <<"sig_fc"/utf8>>).

-file("test/gemini_test.gleam", 129).
-spec decode_thought_response_test() -> nil.
decode_thought_response_test() ->
    Raw_json = <<"
    {
      \"candidates\": [
        {
          \"content\": {
            \"parts\": [
              {
                \"text\": \"I should check the time.\",
                \"thought\": true,
                \"thoughtSignature\": \"sig_thought\"
              }
            ]
          }
        }
      ]
    }
  "/utf8>>,
    Result = providers@gemini:decode_response(Raw_json),
    _pipe = Result,
    gleeunit@should:be_ok(_pipe),
    {Thought@1, Sig@1} = case Result of
        {ok, [{thought, Thought, {some, Sig}}]} -> {Thought, Sig};
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"gemini_test"/utf8>>,
                        function => <<"decode_thought_response_test"/utf8>>,
                        line => 152,
                        value => _assert_fail,
                        start => 3802,
                        'end' => 3861,
                        pattern_start => 3813,
                        pattern_end => 3852})
    end,
    _pipe@1 = Thought@1,
    gleeunit@should:equal(_pipe@1, <<"I should check the time."/utf8>>),
    _pipe@2 = Sig@1,
    gleeunit@should:equal(_pipe@2, <<"sig_thought"/utf8>>).

-file("test/gemini_test.gleam", 157).
-spec decode_empty_candidates_response_test() -> nil.
decode_empty_candidates_response_test() ->
    Raw_json = <<"{\"candidates\": []}"/utf8>>,
    Result = providers@gemini:decode_response(Raw_json),
    _pipe = Result,
    gleeunit@should:be_ok(_pipe),
    _pipe@1 = Result,
    gleeunit@should:equal(_pipe@1, {ok, []}).

-file("test/gemini_test.gleam", 165).
-spec decode_malformed_json_test() -> gleam@json:decode_error().
decode_malformed_json_test() ->
    Raw_json = <<"invalid json"/utf8>>,
    Result = providers@gemini:decode_response(Raw_json),
    _pipe = Result,
    gleeunit@should:be_error(_pipe).

-file("test/gemini_test.gleam", 171).
-spec message_with_function_response_to_json_test() -> nil.
message_with_function_response_to_json_test() ->
    Response_json = gleam@json:object(
        [{<<"result"/utf8>>, gleam@json:string(<<"ok"/utf8>>)}]
    ),
    Msg = {message,
        <<"function"/utf8>>,
        [{function_response, <<"my_tool"/utf8>>, Response_json}]},
    Json_str = begin
        _pipe = providers@gemini:message_to_json(Msg),
        gleam@json:to_string(_pipe)
    end,
    _pipe@1 = Json_str,
    _pipe@2 = gleam_stdlib:contains_string(
        _pipe@1,
        <<"\"functionResponse\""/utf8>>
    ),
    gleeunit@should:be_true(_pipe@2),
    _pipe@3 = Json_str,
    _pipe@4 = gleam_stdlib:contains_string(
        _pipe@3,
        <<"\"name\":\"my_tool\""/utf8>>
    ),
    gleeunit@should:be_true(_pipe@4),
    _pipe@5 = Json_str,
    _pipe@6 = gleam_stdlib:contains_string(
        _pipe@5,
        <<"\"response\":{\"result\":\"ok\"}"/utf8>>
    ),
    gleeunit@should:be_true(_pipe@6).

-file("test/gemini_test.gleam", 187).
-spec build_request_body_minimal_test() -> nil.
build_request_body_minimal_test() ->
    History = [{message, <<"user"/utf8>>, [{text, <<"Hi"/utf8>>, none}]}],
    Body = providers@gemini:build_request_body(History, none, []),
    _pipe = Body,
    _pipe@1 = gleam_stdlib:contains_string(_pipe, <<"\"contents\""/utf8>>),
    gleeunit@should:be_true(_pipe@1),
    _pipe@2 = Body,
    _pipe@3 = gleam_stdlib:contains_string(
        _pipe@2,
        <<"\"system_instruction\""/utf8>>
    ),
    gleeunit@should:be_false(_pipe@3),
    _pipe@4 = Body,
    _pipe@5 = gleam_stdlib:contains_string(_pipe@4, <<"\"tools\""/utf8>>),
    gleeunit@should:be_false(_pipe@5).
