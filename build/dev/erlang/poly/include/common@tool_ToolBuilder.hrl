-record(tool_builder, {
    name :: binary(),
    description :: binary(),
    properties :: list({binary(), gleam@json:json()}),
    required :: list(binary())
}).
