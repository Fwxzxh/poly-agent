-record(tool, {
    declaration :: common@types:function_declaration(),
    executor :: fun((gleam@json:json()) -> gleam@json:json())
}).
