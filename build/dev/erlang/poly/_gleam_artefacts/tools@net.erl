-module(tools@net).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/tools/net.gleam").
-export([http_get_tool/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(" This module contains network-related tools.\n").

-file("src/tools/net.gleam", 21).
-spec http_get_executor(gleam@json:json()) -> gleam@json:json().
http_get_executor(Args) ->
    Decoder = begin
        gleam@dynamic@decode:field(
            <<"url"/utf8>>,
            {decoder, fun gleam@dynamic@decode:decode_string/1},
            fun(Url) -> gleam@dynamic@decode:success(Url) end
        )
    end,
    case gleam@dynamic@decode:run(poly_ffi:identity(Args), Decoder) of
        {ok, Url@1} ->
            case gleam@http@request:to(Url@1) of
                {ok, Req} ->
                    Req@1 = begin
                        _pipe = Req,
                        gleam@http@request:set_method(_pipe, get)
                    end,
                    case gleam@httpc:send(Req@1) of
                        {ok, Resp} ->
                            gleam@json:object(
                                [{<<"body"/utf8>>,
                                        gleam@json:string(
                                            erlang:element(4, Resp)
                                        )}]
                            );

                        {error, Err} ->
                            gleam@json:object(
                                [{<<"error"/utf8>>,
                                        gleam@json:string(
                                            <<"HTTP request failed: "/utf8,
                                                (gleam@string:inspect(Err))/binary>>
                                        )}]
                            )
                    end;

                {error, _} ->
                    gleam@json:object(
                        [{<<"error"/utf8>>,
                                gleam@json:string(<<"Invalid URL"/utf8>>)}]
                    )
            end;

        {error, _} ->
            gleam@json:object(
                [{<<"error"/utf8>>,
                        gleam@json:string(
                            <<"Missing or invalid 'url' argument"/utf8>>
                        )}]
            )
    end.

-file("src/tools/net.gleam", 12).
?DOC(" Returns the \"http_get\" tool.\n").
-spec http_get_tool() -> tools@utils:tool().
http_get_tool() ->
    _pipe = tools@utils:new(
        <<"http_get"/utf8>>,
        <<"Performs an HTTP GET request and returns the response body."/utf8>>
    ),
    _pipe@1 = tools@utils:with_string_param(
        _pipe,
        <<"url"/utf8>>,
        <<"The URL to fetch"/utf8>>,
        true
    ),
    tools@utils:build_tool(_pipe@1, fun http_get_executor/1).
