-module(developer_test).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "test/developer_test.gleam").
-export([get_tools_test/0]).

-file("test/developer_test.gleam", 5).
-spec get_tools_test() -> nil.
get_tools_test() ->
    Tools = skills@developer:get_tools(),
    _pipe = Tools,
    _pipe@1 = erlang:length(_pipe),
    gleeunit@should:equal(_pipe@1, 4),
    Names = gleam@list:map(
        Tools,
        fun(T) -> erlang:element(2, erlang:element(2, T)) end
    ),
    _pipe@2 = Names,
    _pipe@3 = gleam@list:contains(_pipe@2, <<"read_file"/utf8>>),
    gleeunit@should:be_true(_pipe@3),
    _pipe@4 = Names,
    _pipe@5 = gleam@list:contains(_pipe@4, <<"list_files"/utf8>>),
    gleeunit@should:be_true(_pipe@5),
    _pipe@6 = Names,
    _pipe@7 = gleam@list:contains(_pipe@6, <<"execute_command"/utf8>>),
    gleeunit@should:be_true(_pipe@7),
    _pipe@8 = Names,
    _pipe@9 = gleam@list:contains(_pipe@8, <<"http_get"/utf8>>),
    gleeunit@should:be_true(_pipe@9).
