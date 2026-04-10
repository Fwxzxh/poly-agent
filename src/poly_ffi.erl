-module(poly_ffi).

-export([identity/1, read_line/0, run_command/1, get_system_info/0, stream_request/3]).

identity(X) ->
    X.

read_line() ->
    io:get_line("").

get_system_info() ->
    {os:type(), os:version(), erlang:system_info(system_architecture), os:getenv("USER")}.

stream_request(Url, Body, Callback) ->
    case httpc:request(post,
                       {binary_to_list(Url),
                        [{"content-type", "application/json"}],
                        "application/json",
                        Body},
                       [],
                       [{sync, false}, {stream, self}])
    of
        {ok, RequestId} ->
            collect_stream_data(RequestId, <<>>, Callback);
        {error, Reason} ->
            {error, Reason}
    end.

collect_stream_data(RequestId, Acc, Callback) ->
    receive
        {http, {RequestId, stream_start, _Headers}} ->
            collect_stream_data(RequestId, Acc, Callback);
        {http, {RequestId, stream, Data}} ->
            Callback(Data),
            collect_stream_data(RequestId, <<Acc/binary, Data/binary>>, Callback);
        {http, {RequestId, stream_end, _Headers}} ->
            {ok, Acc};
        {http, {RequestId, {error, Reason}}} ->
            {error, Reason}
    after 60000 ->
        {error, timeout}
    end.

run_command(Command) ->
    Port =
        open_port({spawn, binary_to_list(Command)},
                  [binary, exit_status, use_stdio, stderr_to_stdout]),
    collect_port_data(Port, <<>>).

collect_port_data(Port, Acc) ->
    receive
        {Port, {data, Data}} ->
            collect_port_data(Port, <<Acc/binary, Data/binary>>);
        {Port, {exit_status, Status}} ->
            {Status, Acc}
    end.
