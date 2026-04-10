-module(providers@gemini).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/providers/gemini.gleam").
-export([part_to_json/1, message_to_json/1, tool_to_json/1, decode_response/1, build_request_body/3, call/6, gemini_provider/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(
    " This module provides the Gemini provider implementation.\n"
    " It handles the conversion between common types and the JSON format expected by Gemini.\n"
).

-file("src/providers/gemini.gleam", 65).
-spec add_signature(
    list({binary(), gleam@json:json()}),
    gleam@option:option(binary())
) -> gleam@json:json().
add_signature(Fields, Signature) ->
    case Signature of
        {some, S} ->
            gleam@json:object(
                [{<<"thoughtSignature"/utf8>>, gleam@json:string(S)} | Fields]
            );

        none ->
            gleam@json:object(Fields)
    end.

-file("src/providers/gemini.gleam", 30).
?DOC(" Encodes a single `Part` of a message into JSON.\n").
-spec part_to_json(common@types:part()) -> gleam@json:json().
part_to_json(Part) ->
    case Part of
        {text, Text, Signature} ->
            Fields = [{<<"text"/utf8>>, gleam@json:string(Text)}],
            add_signature(Fields, Signature);

        {thought, Thought, Signature@1} ->
            Fields@1 = [{<<"text"/utf8>>, gleam@json:string(Thought)},
                {<<"thought"/utf8>>, gleam@json:bool(true)}],
            add_signature(Fields@1, Signature@1);

        {function_call, Name, Args, Signature@2} ->
            Fields@2 = [{<<"functionCall"/utf8>>,
                    gleam@json:object(
                        [{<<"name"/utf8>>, gleam@json:string(Name)},
                            {<<"args"/utf8>>,
                                common@types:dynamic_to_json(Args)}]
                    )}],
            add_signature(Fields@2, Signature@2);

        {function_response, Name@1, Response} ->
            gleam@json:object(
                [{<<"functionResponse"/utf8>>,
                        gleam@json:object(
                            [{<<"name"/utf8>>, gleam@json:string(Name@1)},
                                {<<"response"/utf8>>, Response}]
                        )}]
            )
    end.

-file("src/providers/gemini.gleam", 22).
?DOC(" Encodes a `Message` into a JSON object compatible with Gemini API.\n").
-spec message_to_json(common@types:message()) -> gleam@json:json().
message_to_json(Message) ->
    gleam@json:object(
        [{<<"role"/utf8>>, gleam@json:string(erlang:element(2, Message))},
            {<<"parts"/utf8>>,
                gleam@json:array(erlang:element(3, Message), fun part_to_json/1)}]
    ).

-file("src/providers/gemini.gleam", 76).
?DOC(" Encodes a `Tool` (list of function declarations) into JSON.\n").
-spec tool_to_json(common@types:tool()) -> gleam@json:json().
tool_to_json(Tool) ->
    gleam@json:object(
        [{<<"function_declarations"/utf8>>,
                gleam@json:array(
                    erlang:element(2, Tool),
                    fun(Fd) ->
                        Fields = [{<<"name"/utf8>>,
                                gleam@json:string(erlang:element(2, Fd))},
                            {<<"description"/utf8>>,
                                gleam@json:string(erlang:element(3, Fd))}],
                        Fields@1 = case erlang:element(4, Fd) of
                            {some, Params} ->
                                [{<<"parameters"/utf8>>, Params} | Fields];

                            none ->
                                Fields
                        end,
                        gleam@json:object(Fields@1)
                    end
                )}]
    ).

-file("src/providers/gemini.gleam", 96).
?DOC(" Decodes a JSON response string from Gemini into a list of message parts.\n").
-spec decode_response(binary()) -> {ok, list(common@types:part())} |
    {error, gleam@json:decode_error()}.
decode_response(Json_string) ->
    Part_decoder = gleam@dynamic@decode:one_of(
        begin
            gleam@dynamic@decode:field(
                <<"text"/utf8>>,
                {decoder, fun gleam@dynamic@decode:decode_string/1},
                fun(Text) ->
                    gleam@dynamic@decode:optional_field(
                        <<"thoughtSignature"/utf8>>,
                        none,
                        gleam@dynamic@decode:optional(
                            {decoder, fun gleam@dynamic@decode:decode_string/1}
                        ),
                        fun(Sig) ->
                            gleam@dynamic@decode:optional_field(
                                <<"thought"/utf8>>,
                                false,
                                {decoder,
                                    fun gleam@dynamic@decode:decode_bool/1},
                                fun(Is_thought) -> case Is_thought of
                                        true ->
                                            gleam@dynamic@decode:success(
                                                {thought, Text, Sig}
                                            );

                                        false ->
                                            gleam@dynamic@decode:success(
                                                {text, Text, Sig}
                                            )
                                    end end
                            )
                        end
                    )
                end
            )
        end,
        [begin
                gleam@dynamic@decode:subfield(
                    [<<"functionCall"/utf8>>, <<"name"/utf8>>],
                    {decoder, fun gleam@dynamic@decode:decode_string/1},
                    fun(Name) ->
                        gleam@dynamic@decode:subfield(
                            [<<"functionCall"/utf8>>, <<"args"/utf8>>],
                            {decoder, fun gleam@dynamic@decode:decode_dynamic/1},
                            fun(Args) ->
                                gleam@dynamic@decode:optional_field(
                                    <<"thoughtSignature"/utf8>>,
                                    none,
                                    gleam@dynamic@decode:optional(
                                        {decoder,
                                            fun gleam@dynamic@decode:decode_string/1}
                                    ),
                                    fun(Sig@1) ->
                                        gleam@dynamic@decode:success(
                                            {function_call, Name, Args, Sig@1}
                                        )
                                    end
                                )
                            end
                        )
                    end
                )
            end]
    ),
    Decoder = begin
        gleam@dynamic@decode:field(
            <<"candidates"/utf8>>,
            gleam@dynamic@decode:list(
                gleam@dynamic@decode:at(
                    [<<"content"/utf8>>, <<"parts"/utf8>>],
                    gleam@dynamic@decode:list(Part_decoder)
                )
            ),
            fun(Parts_list) -> case Parts_list of
                    [Parts | _] ->
                        gleam@dynamic@decode:success(Parts);

                    [] ->
                        gleam@dynamic@decode:success([])
                end end
        )
    end,
    gleam@json:parse(Json_string, Decoder).

-file("src/providers/gemini.gleam", 192).
-spec identity(IFD) -> IFD.
identity(X) ->
    X.

-file("src/providers/gemini.gleam", 143).
?DOC(" Constructs the JSON request body for the Gemini API.\n").
-spec build_request_body(
    list(common@types:message()),
    gleam@option:option(binary()),
    list(common@types:function_declaration())
) -> binary().
build_request_body(History, System_instruction, Tool_declarations) ->
    Contents = {<<"contents"/utf8>>,
        gleam@json:array(History, fun message_to_json/1)},
    Generation_config = {<<"generationConfig"/utf8>>,
        gleam@json:object(
            [{<<"thinkingConfig"/utf8>>,
                    gleam@json:object(
                        [{<<"includeThoughts"/utf8>>, gleam@json:bool(true)},
                            {<<"thinkingBudget"/utf8>>, gleam@json:int(8192)}]
                    )}]
        )},
    Mut_fields = [Contents, Generation_config],
    Mut_fields@1 = case System_instruction of
        {some, Instr} ->
            [{<<"system_instruction"/utf8>>,
                    gleam@json:object(
                        [{<<"parts"/utf8>>,
                                gleam@json:array(
                                    [gleam@json:object(
                                            [{<<"text"/utf8>>,
                                                    gleam@json:string(Instr)}]
                                        )],
                                    fun identity/1
                                )}]
                    )} |
                Mut_fields];

        none ->
            Mut_fields
    end,
    Fields = case Tool_declarations of
        [] ->
            Mut_fields@1;

        _ ->
            [{<<"tools"/utf8>>,
                    gleam@json:array(
                        [{tool, Tool_declarations}],
                        fun tool_to_json/1
                    )} |
                Mut_fields@1]
    end,
    _pipe = gleam@json:object(Fields),
    gleam@json:to_string(_pipe).

-file("src/providers/gemini.gleam", 197).
?DOC(" Makes the HTTP request to the Gemini API.\n").
-spec call(
    list(common@types:message()),
    gleam@option:option(binary()),
    binary(),
    binary(),
    list(common@types:function_declaration()),
    boolean()
) -> {ok, list(common@types:part())} | {error, nil}.
call(History, System_instruction, Api_key, Model, Tool_declarations, Debug) ->
    Url = <<<<<<"https://generativelanguage.googleapis.com/v1beta/models/"/utf8,
                Model/binary>>/binary,
            ":generateContent?key="/utf8>>/binary,
        Api_key/binary>>,
    Body = build_request_body(History, System_instruction, Tool_declarations),
    case Debug of
        true ->
            gleam_stdlib:println(<<"--- DEBUG: Request Body ---"/utf8>>),
            gleam_stdlib:println(Body),
            gleam_stdlib:println(<<"---------------------------"/utf8>>);

        false ->
            nil
    end,
    Req@1 = case gleam@http@request:to(Url) of
        {ok, Req} -> Req;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"providers/gemini"/utf8>>,
                        function => <<"call"/utf8>>,
                        line => 222,
                        value => _assert_fail,
                        start => 5774,
                        'end' => 5810,
                        pattern_start => 5785,
                        pattern_end => 5792})
    end,
    Req@2 = begin
        _pipe = Req@1,
        _pipe@1 = gleam@http@request:set_method(_pipe, post),
        _pipe@2 = gleam@http@request:set_body(_pipe@1, Body),
        gleam@http@request:set_header(
            _pipe@2,
            <<"content-type"/utf8>>,
            <<"application/json"/utf8>>
        )
    end,
    Resp@1 = case gleam@httpc:send(Req@2) of
        {ok, Resp} -> Resp;
        _assert_fail@1 ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"providers/gemini"/utf8>>,
                        function => <<"call"/utf8>>,
                        line => 229,
                        value => _assert_fail@1,
                        start => 5963,
                        'end' => 6000,
                        pattern_start => 5974,
                        pattern_end => 5982})
    end,
    case Debug of
        true ->
            gleam_stdlib:println(<<"--- DEBUG: Response Body ---"/utf8>>),
            gleam_stdlib:println(erlang:element(4, Resp@1)),
            gleam_stdlib:println(<<"----------------------------"/utf8>>);

        false ->
            nil
    end,
    case decode_response(erlang:element(4, Resp@1)) of
        {ok, Parts} ->
            {ok, Parts};

        {error, E} ->
            gleam_stdlib:println(
                <<"--- API Error / Unexpected Response ---"/utf8>>
            ),
            gleam_stdlib:println(
                <<"Status: "/utf8,
                    (erlang:integer_to_binary(erlang:element(2, Resp@1)))/binary>>
            ),
            gleam_stdlib:println(
                <<"Body: "/utf8, (erlang:element(4, Resp@1))/binary>>
            ),
            gleam_stdlib:println(
                <<"Error details: "/utf8, (gleam@string:inspect(E))/binary>>
            ),
            {error, nil}
    end.

-file("src/providers/gemini.gleam", 17).
-spec gemini_provider() -> providers@interface:provider().
gemini_provider() ->
    {provider, <<"gemini"/utf8>>, fun call/6}.
