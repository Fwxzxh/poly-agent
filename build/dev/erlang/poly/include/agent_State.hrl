-record(state, {
    history :: list(common@types:message()),
    system_instruction :: gleam@option:option(binary()),
    api_key :: binary(),
    model :: binary(),
    provider :: providers@interface:provider(),
    tools :: list(tools@utils:tool()),
    on_event :: fun((common@types:agent_event()) -> nil),
    debug :: boolean()
}).
