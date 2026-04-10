-module(tools_test).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "test/tools_test.gleam").
-export([fs_list_files_test/0, fs_read_file_test/0, fs_read_file_not_found_test/0, shell_execute_command_test/0, shell_execute_error_test/0, net_http_get_invalid_url_test/0, net_http_get_missing_arg_test/0]).

-file("test/tools_test.gleam", 16).
-spec prepare_args(binary()) -> gleam@json:json().
prepare_args(Json_string) ->
    Decoded@1 = case gleam@json:parse(
        Json_string,
        {decoder, fun gleam@dynamic@decode:decode_dynamic/1}
    ) of
        {ok, Decoded} -> Decoded;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"tools_test"/utf8>>,
                        function => <<"prepare_args"/utf8>>,
                        line => 17,
                        value => _assert_fail,
                        start => 537,
                        'end' => 614,
                        pattern_start => 548,
                        pattern_end => 559})
    end,
    poly_ffi:identity(Decoded@1).

-file("test/tools_test.gleam", 23).
-spec fs_list_files_test() -> nil.
fs_list_files_test() ->
    Args = prepare_args(<<"{\"directory\": \"src\"}"/utf8>>),
    Tool = tools@fs:list_files_tool(),
    Response = (erlang:element(3, Tool))(Args),
    Json_str = gleam@json:to_string(Response),
    _pipe = Json_str,
    _pipe@1 = gleam_stdlib:contains_string(_pipe, <<"\"files\":"/utf8>>),
    gleeunit@should:be_true(_pipe@1),
    _pipe@2 = Json_str,
    _pipe@3 = gleam_stdlib:contains_string(_pipe@2, <<"agent.gleam"/utf8>>),
    gleeunit@should:be_true(_pipe@3).

-file("test/tools_test.gleam", 33).
-spec fs_read_file_test() -> nil.
fs_read_file_test() ->
    Args = prepare_args(<<"{\"path\": \"gleam.toml\"}"/utf8>>),
    Tool = tools@fs:read_file_tool(),
    Response = (erlang:element(3, Tool))(Args),
    Json_str = gleam@json:to_string(Response),
    _pipe = Json_str,
    _pipe@1 = gleam_stdlib:contains_string(_pipe, <<"poly"/utf8>>),
    gleeunit@should:be_true(_pipe@1).

-file("test/tools_test.gleam", 42).
-spec fs_read_file_not_found_test() -> nil.
fs_read_file_not_found_test() ->
    Args = prepare_args(<<"{\"path\": \"non_existent_file_123.txt\"}"/utf8>>),
    Tool = tools@fs:read_file_tool(),
    Response = (erlang:element(3, Tool))(Args),
    Json_str = gleam@json:to_string(Response),
    _pipe = Json_str,
    _pipe@1 = gleam_stdlib:contains_string(_pipe, <<"\"error\":"/utf8>>),
    gleeunit@should:be_true(_pipe@1).

-file("test/tools_test.gleam", 53).
-spec shell_execute_command_test() -> nil.
shell_execute_command_test() ->
    Args = prepare_args(<<"{\"command\": \"echo 'hello poly'\"}"/utf8>>),
    Tool = tools@shell:execute_command_tool(),
    Response = (erlang:element(3, Tool))(Args),
    Json_str = gleam@json:to_string(Response),
    _pipe = Json_str,
    _pipe@1 = gleam_stdlib:contains_string(_pipe, <<"\"status\":0"/utf8>>),
    gleeunit@should:be_true(_pipe@1),
    _pipe@2 = Json_str,
    _pipe@3 = gleam_stdlib:contains_string(_pipe@2, <<"hello poly"/utf8>>),
    gleeunit@should:be_true(_pipe@3).

-file("test/tools_test.gleam", 63).
-spec shell_execute_error_test() -> nil.
shell_execute_error_test() ->
    Args = prepare_args(
        <<"{\"command\": \"ls /non_existent_folder_xyz\"}"/utf8>>
    ),
    Tool = tools@shell:execute_command_tool(),
    Response = (erlang:element(3, Tool))(Args),
    Json_str = gleam@json:to_string(Response),
    _pipe = Json_str,
    _pipe@1 = gleam_stdlib:contains_string(_pipe, <<"\"status\":0"/utf8>>),
    gleeunit@should:be_false(_pipe@1).

-file("test/tools_test.gleam", 75).
-spec net_http_get_invalid_url_test() -> nil.
net_http_get_invalid_url_test() ->
    Args = prepare_args(<<"{\"url\": \"not-a-url\"}"/utf8>>),
    Tool = tools@net:http_get_tool(),
    Response = (erlang:element(3, Tool))(Args),
    Json_str = gleam@json:to_string(Response),
    _pipe = Json_str,
    _pipe@1 = gleam_stdlib:contains_string(_pipe, <<"\"error\":"/utf8>>),
    gleeunit@should:be_true(_pipe@1).

-file("test/tools_test.gleam", 84).
-spec net_http_get_missing_arg_test() -> nil.
net_http_get_missing_arg_test() ->
    Args = prepare_args(<<"{}"/utf8>>),
    Tool = tools@net:http_get_tool(),
    Response = (erlang:element(3, Tool))(Args),
    Json_str = gleam@json:to_string(Response),
    _pipe = Json_str,
    _pipe@1 = gleam_stdlib:contains_string(
        _pipe,
        <<"Missing or invalid 'url' argument"/utf8>>
    ),
    gleeunit@should:be_true(_pipe@1).
