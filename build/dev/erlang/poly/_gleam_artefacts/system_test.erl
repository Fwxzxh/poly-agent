-module(system_test).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "test/system_test.gleam").
-export([get_info_test/0, format_as_context_test/0]).

-file("test/system_test.gleam", 5).
-spec get_info_test() -> nil.
get_info_test() ->
    Info = tools@system:get_info(),
    _pipe = erlang:element(2, Info),
    _pipe@1 = gleam@string:is_empty(_pipe),
    gleeunit@should:be_false(_pipe@1),
    _pipe@2 = erlang:element(4, Info),
    _pipe@3 = gleam@string:is_empty(_pipe@2),
    gleeunit@should:be_false(_pipe@3),
    _pipe@4 = erlang:element(5, Info),
    _pipe@5 = gleam@string:is_empty(_pipe@4),
    gleeunit@should:be_false(_pipe@5),
    _pipe@6 = erlang:element(6, Info),
    _pipe@7 = gleam@string:is_empty(_pipe@6),
    gleeunit@should:be_false(_pipe@7).

-file("test/system_test.gleam", 15).
-spec format_as_context_test() -> nil.
format_as_context_test() ->
    Info = {system_info,
        <<"unix"/utf8>>,
        <<"1.0"/utf8>>,
        <<"arm64"/utf8>>,
        <<"tester"/utf8>>,
        <<"/tmp"/utf8>>},
    Context = tools@system:format_as_context(Info),
    _pipe = Context,
    _pipe@1 = gleam_stdlib:contains_string(_pipe, <<"System Context:"/utf8>>),
    gleeunit@should:be_true(_pipe@1),
    _pipe@2 = Context,
    _pipe@3 = gleam_stdlib:contains_string(_pipe@2, <<"OS: unix"/utf8>>),
    gleeunit@should:be_true(_pipe@3),
    _pipe@4 = Context,
    _pipe@5 = gleam_stdlib:contains_string(
        _pipe@4,
        <<"Architecture: arm64"/utf8>>
    ),
    gleeunit@should:be_true(_pipe@5),
    _pipe@6 = Context,
    _pipe@7 = gleam_stdlib:contains_string(_pipe@6, <<"User: tester"/utf8>>),
    gleeunit@should:be_true(_pipe@7),
    _pipe@8 = Context,
    _pipe@9 = gleam_stdlib:contains_string(
        _pipe@8,
        <<"Working Directory: /tmp"/utf8>>
    ),
    gleeunit@should:be_true(_pipe@9).
