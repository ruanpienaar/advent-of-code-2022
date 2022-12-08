-module(crappyelfsignaldevice).

-export([
    run/0,
    is_marker/1
]).

run() ->
    find_first_marker(file:read_file("input.txt")).

find_first_marker({ok, Data}) ->
    MarkerLength = 4,
    {ok, NextChars, Rest} = next_x_chars(MarkerLength, Data),
    check_next_char(is_marker(NextChars), MarkerLength, NextChars, Rest).

check_next_char(_, Pos, _PossibleMarker, <<>>) ->
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
    io:format("Line : ~p\n", [Line]),
    <<NextChars:Chars/binary, Rest/binary>> = Line,
    {ok, NextChars, Rest}.

is_marker(<<A:1/binary, B:1/binary, C:1/binary, D:1/binary>>) ->
    length(lists:uniq([A, B, C, D])) =:= 4.