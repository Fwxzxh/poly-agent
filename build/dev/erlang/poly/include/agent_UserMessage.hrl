-record(user_message, {
    content :: binary(),
    reply_to :: gleam@erlang@process:subject(binary())
}).
