-module(poly_ffi).

-export([identity/1, read_line/0, run_command/1, get_system_info/0]).

identity(X) ->
    X.

read_line() ->
    io:get_line("").

get_system_info() ->
    {os:type(), os:version(), erlang:system_info(system_architecture), os:getenv("USER")}.

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
