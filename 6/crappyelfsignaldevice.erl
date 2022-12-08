-module(crappyelfsignaldevice).

-export([
    run/0,
    is_marker/1
]).

-define(MARKER_LENGTH, 14).

run() ->
    find_first_marker(file:read_file("input.txt")).

find_first_marker({ok, Data}) ->
    {ok, NextChars, Rest} = next_x_chars(?MARKER_LENGTH, Data),
    check_next_char(is_marker(NextChars), ?MARKER_LENGTH, NextChars, Rest).

check_next_char(_, _Pos, _PossibleMarker, <<>>) ->
    0;
check_next_char(true, Pos, _PossibleMarker, _Rest) ->
    Pos;
check_next_char(false, Pos, PossibleMarker, Rest) ->
    {ok, NextChars, NewRest} = next_x_chars(1, Rest),
    NextPossibleMarker =
        binary:list_to_bin([
            binary:part(PossibleMarker, {1, byte_size(PossibleMarker)-1}),
            NextChars
        ]),
    check_next_char(is_marker(NextPossibleMarker), Pos+1, NextPossibleMarker, NewRest).

next_x_chars(Chars, Line) ->
    <<NextChars:Chars/binary, Rest/binary>> = Line,
    {ok, NextChars, Rest}.

is_marker(<<X:?MARKER_LENGTH/binary>>) ->
    length(lists:uniq([ C || <<C:1/binary>> <= X ])) =:= MARKER_LENGTH.