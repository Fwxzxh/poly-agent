-module(poly).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/poly.gleam").
-export([main/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(
    " Poly: A modular AI Agent framework for Gleam.\n"
    "\n"
    " This module provides the main entry point for the interactive CLI tool.\n"
    " It initializes the environment, starts the agent actor, and handles\n"
    " the user input loop.\n"
).

-file("src/poly.gleam", 61).
-spec get_api_key() -> binary().
get_api_key() ->
    case dot_env_ffi:get_env(<<"GOOGLE_API_KEY"/utf8>>) of
        {ok, Key} ->
            Key;

        {error, _} ->
            gleam_stdlib:println(
                <<"Error: GOOGLE_API_KEY no encontrada."/utf8>>
            ),
            gleam_stdlib:println(
                <<"Asegúrate de tener un archivo .env o la variable configurada."/utf8>>
            ),
            erlang:error(#{gleam_error => panic,
                    message => <<"Missing API key"/utf8>>,
                    file => <<?FILEPATH/utf8>>,
                    module => <<"poly"/utf8>>,
                    function => <<"get_api_key"/utf8>>,
                    line => 69})
    end.

-file("src/poly.gleam", 74).
-spec is_debug_enabled() -> boolean().
is_debug_enabled() ->
    case dot_env_ffi:get_env(<<"DEBUG"/utf8>>) of
        {ok, <<"true"/utf8>>} ->
            true;

        _ ->
            false
    end.

-file("src/poly.gleam", 83).
?DOC(
    " Handles events emitted by the agent during its reasoning process.\n"
    " This implementation prints thoughts and tool calls to the console with ANSI colors.\n"
).
-spec handle_event(common@types:agent_event()) -> nil.
handle_event(Event) ->
    case Event of
        {thought_event, Text} ->
            gleam_stdlib:println(
                <<<<"\x{1b}[2m\x{1b}[3m> Thinking: "/utf8, Text/binary>>/binary,
                    "\x{1b}[0m"/utf8>>
            );

        {tool_start_event, Name, Args} ->
            Args_str = gleam@json:to_string(Args),
            gleam_stdlib:println(
                <<<<<<<<"\x{1b}[34m\x{1b}[1m> Tool Call: "/utf8, Name/binary>>/binary,
                            "("/utf8>>/binary,
                        Args_str/binary>>/binary,
                    ")\x{1b}[0m"/utf8>>
            );

        {tool_result_event, _, _} ->
            nil
    end.

-file("src/poly.gleam", 108).
?DOC(" The interactive loop that reads user input and sends it to the agent.\n").
-spec chat_loop(gleam@erlang@process:subject(agent:agent_message())) -> nil.
chat_loop(Agent_subject) ->
    gleam_stdlib:print(<<"> "/utf8>>),
    Input = poly_ffi:read_line(),
    case Input of
        <<"exit\n"/utf8>> ->
            gleam_stdlib:println(<<"¡Adiós!"/utf8>>);

        _ ->
            Reply_subject = gleam@erlang@process:new_subject(),
            gleam@erlang@process:send(
                Agent_subject,
                {user_message, Input, Reply_subject}
            ),
            Response = gleam_erlang_ffi:'receive'(Reply_subject),
            gleam_stdlib:println(<<"Agent: "/utf8, Response/binary>>),
            chat_loop(Agent_subject)
    end.

-file("src/poly.gleam", 27).
?DOC(
    " The entry point for the Poly AI Agent CLI.\n"
    "\n"
    " It performs the following steps:\n"
    " 1. Loads environment variables from a `.env` file.\n"
    " 2. Retrieves the `GOOGLE_API_KEY`.\n"
    " 3. Initializes the reasoning tools (Developer skills).\n"
    " 4. Starts the Agent actor using the Gemini provider.\n"
    " 5. Enters an interactive chat loop.\n"
).
-spec main() -> nil.
main() ->
    dot_env:load_default(),
    Api_key = get_api_key(),
    Debug = is_debug_enabled(),
    Available_tools = skills@developer:get_tools(),
    System_info = tools@system:get_info(),
    System_prompt = <<"You are Poly Agent, a helpful AI assistant.\n"/utf8,
        (tools@system:format_as_context(System_info))/binary>>,
    Started@1 = case agent:start(
        Api_key,
        providers@gemini:gemini_provider(),
        Available_tools,
        {some, System_prompt},
        fun handle_event/1,
        Debug
    ) of
        {ok, Started} -> Started;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"poly"/utf8>>,
                        function => <<"main"/utf8>>,
                        line => 42,
                        value => _assert_fail,
                        start => 1222,
                        'end' => 1399,
                        pattern_start => 1233,
                        pattern_end => 1244})
    end,
    Agent_subject = erlang:element(3, Started@1),
    gleam_stdlib:println(<<"--- Poly AI Agent (Gemini) ---"/utf8>>),
    gleam_stdlib:println(<<"Configuración cargada correctamente."/utf8>>),
    gleam_stdlib:println(
        <<"Escribe tu mensaje y presiona Enter. Escribe 'exit' para salir."/utf8>>
    ),
    chat_loop(Agent_subject).
