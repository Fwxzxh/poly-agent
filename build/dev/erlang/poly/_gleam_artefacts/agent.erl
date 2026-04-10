-module(agent).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/agent.gleam").
-export([get_function_calls/1, extract_text/1, execute_tools/3, start/6]).
-export_type([state/0, agent_message/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(
    " This module implements the AI Agent using the Gleam Actor (OTP) pattern.\n"
    " It manages conversation state and the reasoning loop for tool usage.\n"
).

-type state() :: {state,
        list(common@types:message()),
        gleam@option:option(binary()),
        binary(),
        binary(),
        providers@interface:provider(),
        list(tools@utils:tool()),
        fun((common@types:agent_event()) -> nil),
        boolean()}.

-type agent_message() :: {user_message,
        binary(),
        gleam@erlang@process:subject(binary())}.

-file("src/agent.gleam", 162).
-spec handle_part_events(
    common@types:part(),
    fun((common@types:agent_event()) -> nil)
) -> nil.
handle_part_events(Part, On_event) ->
    case Part of
        {thought, Text, _} ->
            On_event({thought_event, Text});

        {function_call, Name, Args, _} ->
            On_event(
                {tool_start_event, Name, common@types:dynamic_to_json(Args)}
            );

        _ ->
            nil
    end.

-file("src/agent.gleam", 197).
?DOC(" Helper to filter out and identify function calls from a list of parts.\n").
-spec get_function_calls(list(common@types:part())) -> list({binary(),
    gleam@dynamic:dynamic_()}).
get_function_calls(Parts) ->
    gleam@list:filter_map(Parts, fun(P) -> case P of
                {function_call, Name, Args, _} ->
                    {ok, {Name, Args}};

                _ ->
                    {error, nil}
            end end).

-file("src/agent.gleam", 207).
?DOC(" Helper to extract the first text part from a list of message parts.\n").
-spec extract_text(list(common@types:part())) -> binary().
extract_text(Parts) ->
    Texts = gleam@list:filter_map(Parts, fun(P) -> case P of
                {text, T, _} ->
                    {ok, T};

                _ ->
                    {error, nil}
            end end),
    case Texts of
        [] ->
            _pipe = gleam@list:filter_map(Parts, fun(P@1) -> case P@1 of
                        {thought, T@1, _} ->
                            {ok, T@1};

                        _ ->
                            {error, nil}
                    end end),
            gleam@string:join(_pipe, <<"\n"/utf8>>);

        _ ->
            gleam@string:join(Texts, <<"\n"/utf8>>)
    end.

-file("src/agent.gleam", 172).
?DOC(" Executes the tools requested by the model and returns the responses as message parts.\n").
-spec execute_tools(
    list({binary(), gleam@dynamic:dynamic_()}),
    list(tools@utils:tool()),
    fun((common@types:agent_event()) -> nil)
) -> list(common@types:part()).
execute_tools(Calls, Available_tools, On_event) ->
    gleam@list:map(
        Calls,
        fun(Call) ->
            {Name, Args} = Call,
            Tool = gleam@list:find(
                Available_tools,
                fun(T) -> erlang:element(2, erlang:element(2, T)) =:= Name end
            ),
            case Tool of
                {ok, T@1} ->
                    Response = (erlang:element(3, T@1))(poly_ffi:identity(Args)),
                    On_event({tool_result_event, Name, Response}),
                    {function_response, Name, Response};

                {error, _} ->
                    Err = gleam@json:object(
                        [{<<"error"/utf8>>,
                                gleam@json:string(<<"Tool not found"/utf8>>)}]
                    ),
                    On_event({tool_result_event, Name, Err}),
                    {function_response, Name, Err}
            end
        end
    ).

-file("src/agent.gleam", 98).
?DOC(
    " Orchestrates the conversation with the AI provider.\n"
    " If the model requests tool usage, this function executes the tools\n"
    " and sends the results back to the provider in a recursive loop.\n"
).
-spec run_reasoning_loop(
    list(common@types:message()),
    gleam@option:option(binary()),
    binary(),
    binary(),
    providers@interface:provider(),
    list(tools@utils:tool()),
    fun((common@types:agent_event()) -> nil),
    integer(),
    boolean()
) -> {binary(), list(common@types:message())}.
run_reasoning_loop(
    History,
    System_instruction,
    Api_key,
    Model,
    Provider,
    Available_tools,
    On_event,
    Max_steps,
    Debug
) ->
    case Max_steps of
        0 ->
            {<<"I've reached the maximum number of reasoning steps."/utf8>>,
                History};

        _ ->
            Tool_declarations = gleam@list:map(
                Available_tools,
                fun(T) -> erlang:element(2, T) end
            ),
            Response = (erlang:element(3, Provider))(
                History,
                System_instruction,
                Api_key,
                Model,
                Tool_declarations,
                Debug
            ),
            case Response of
                {error, _} ->
                    {<<"I'm sorry, I encountered an error processing your request."/utf8>>,
                        History};

                {ok, Parts} ->
                    gleam@list:each(
                        Parts,
                        fun(P) -> handle_part_events(P, On_event) end
                    ),
                    Model_msg = {message, <<"model"/utf8>>, Parts},
                    Updated_history = lists:append(History, [Model_msg]),
                    Function_calls = get_function_calls(Parts),
                    case Function_calls of
                        [] ->
                            {extract_text(Parts), Updated_history};

                        Calls ->
                            Tool_responses = execute_tools(
                                Calls,
                                Available_tools,
                                On_event
                            ),
                            Tool_msg = {message,
                                <<"function"/utf8>>,
                                Tool_responses},
                            run_reasoning_loop(
                                lists:append(Updated_history, [Tool_msg]),
                                System_instruction,
                                Api_key,
                                Model,
                                Provider,
                                Available_tools,
                                On_event,
                                Max_steps - 1,
                                Debug
                            )
                    end
            end
    end.

-file("src/agent.gleam", 70).
?DOC(" The main actor loop. Handles incoming messages and updates state.\n").
-spec loop(state(), agent_message()) -> gleam@otp@actor:next(state(), agent_message()).
loop(State, Message) ->
    case Message of
        {user_message, Content, Reply_to} ->
            User_msg = {message, <<"user"/utf8>>, [{text, Content, none}]},
            New_history = lists:append(erlang:element(2, State), [User_msg]),
            {Response_text, Final_history} = run_reasoning_loop(
                New_history,
                erlang:element(3, State),
                erlang:element(4, State),
                erlang:element(5, State),
                erlang:element(6, State),
                erlang:element(7, State),
                erlang:element(8, State),
                10,
                erlang:element(9, State)
            ),
            gleam@erlang@process:send(Reply_to, Response_text),
            gleam@otp@actor:continue(
                {state,
                    Final_history,
                    erlang:element(3, State),
                    erlang:element(4, State),
                    erlang:element(5, State),
                    erlang:element(6, State),
                    erlang:element(7, State),
                    erlang:element(8, State),
                    erlang:element(9, State)}
            )
    end.

-file("src/agent.gleam", 44).
?DOC(" Starts the agent actor with an initial configuration.\n").
-spec start(
    binary(),
    providers@interface:provider(),
    list(tools@utils:tool()),
    gleam@option:option(binary()),
    fun((common@types:agent_event()) -> nil),
    boolean()
) -> {ok,
        gleam@otp@actor:started(gleam@erlang@process:subject(agent_message()))} |
    {error, gleam@otp@actor:start_error()}.
start(Api_key, Provider, Initial_tools, System_instruction, On_event, Debug) ->
    Initial_state = {state,
        [],
        System_instruction,
        Api_key,
        <<"gemini-3.1-flash-lite-preview"/utf8>>,
        Provider,
        Initial_tools,
        On_event,
        Debug},
    _pipe = gleam@otp@actor:new(Initial_state),
    _pipe@1 = gleam@otp@actor:on_message(_pipe, fun loop/2),
    gleam@otp@actor:start(_pipe@1).
