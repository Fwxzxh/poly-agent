-module(poly_ffi).

-export([identity/1, read_line/0, run_command/1, get_system_info/0, stream_request/3, set_env/2]).

identity(X) ->
    X.

set_env(Name, Value) ->
    os:putenv(binary_to_list(Name), binary_to_list(Value)),
    ok.

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
            collect_stream_data(RequestId, <<>>, Callback, <<>>);
        {error, Reason} ->
            {error, Reason}
    end.

collect_stream_data(RequestId, Acc, Callback, FullAcc) ->
    receive
        {http, {RequestId, stream_start, _Headers}} ->
            collect_stream_data(RequestId, Acc, Callback, FullAcc);
        {http, {RequestId, stream, Data}} ->
            NewAcc = <<Acc/binary, Data/binary>>,
            {Remaining, Objects} = parse_json_stream(NewAcc),
            lists:foreach(Callback, Objects),
            collect_stream_data(RequestId, Remaining, Callback, <<FullAcc/binary, Data/binary>>);
        {http, {RequestId, stream_end, _Headers}} ->
            {ok, FullAcc};
        {http, {RequestId, {error, Reason}}} ->
            {error, Reason}
    after 60000 ->
        {error, timeout}
    end.

parse_json_stream(Data) ->
    % Strip leading whitespace, commas, and array start
    case Data of
        <<C, Rest/binary>> when C =:= $[; C =:= $,; C =:= $\s; C =:= $\n; C =:= $\r; C =:= $\t ->
            parse_json_stream(Rest);
        _ ->
            case find_complete_json(Data, 0, 0, <<>>) of
                {ok, Object, Remaining} ->
                    {RestRemaining, FurtherObjects} = parse_json_stream(Remaining),
                    {RestRemaining, [Object | FurtherObjects]};
                incomplete ->
                    {Data, []}
            end
    end.

find_complete_json(<<>>, _, _, _) ->
    incomplete;
find_complete_json(<<$\\, C, Rest/binary>>, Braces, 1, Acc) ->
    find_complete_json(Rest, Braces, 1, <<Acc/binary, $\\, C>>);
find_complete_json(<<$", Rest/binary>>, Braces, 0, Acc) ->
    find_complete_json(Rest, Braces, 1, <<Acc/binary, $">>);
find_complete_json(<<$", Rest/binary>>, Braces, 1, Acc) ->
    find_complete_json(Rest, Braces, 0, <<Acc/binary, $">>);
find_complete_json(<<${, Rest/binary>>, Braces, 0, Acc) ->
    find_complete_json(Rest, Braces + 1, 0, <<Acc/binary, ${>>);
find_complete_json(<<$}, Rest/binary>>, 1, 0, Acc) ->
    {ok, <<Acc/binary, $}>>, Rest};
find_complete_json(<<$}, Rest/binary>>, Braces, 0, Acc) when Braces > 1 ->
    find_complete_json(Rest, Braces - 1, 0, <<Acc/binary, $}>>);
find_complete_json(<<C, Rest/binary>>, Braces, Quotes, Acc) ->
    find_complete_json(Rest, Braces, Quotes, <<Acc/binary, C>>).

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
