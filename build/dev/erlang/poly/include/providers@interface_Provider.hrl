-record(provider, {
    name :: binary(),
    call :: fun((list(common@types:message()), gleam@option:option(binary()), binary(), binary(), list(common@types:function_declaration()), boolean()) -> {ok,
            list(common@types:part())} |
        {error, nil})
}).
