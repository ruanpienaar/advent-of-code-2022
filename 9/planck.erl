-module(planck).

% -export([
%     run/0
% ]).

-compile(export_all).

% {ok, _} = c(planck), planck:run().
% Second attempt 6522, too high!


run() ->
    36 =
    % X = run_instructions(file:open("test-input.txt", [read, read_ahead, binary])),
    X = run_instructions(file:open("test-input2.txt", [read, read_ahead, binary])),
    io:format("~p\n", [X]).

run_instructions({ok, FPID}) ->
    run_instructions(FPID, file:read_line(FPID), [{0, 0}, {0, 0}], sets:new()).

get_num_tail_visits(TailVisits) ->
    % io:format("TailVisits ~p\n", [sets:to_list(TailVisits)]),
    sets:size(TailVisits).

run_instructions(_FPID, eof, _Rope, TailVisits) ->
    get_num_tail_visits(TailVisits);
    % Rope;
run_instructions(FPID, {ok, Line}, Rope, TailVisits) ->
    {NewRope, NewTailVisits} = move_x_times(line_to_instruction(Line), Rope, TailVisits),
    run_instructions(FPID, file:read_line(FPID), NewRope, NewTailVisits).

line_to_instruction(Line) ->
    {match, [[D], Amount]} =
        re:run(Line, <<"^([U|R|D|L]) (\\d+)">>, [{capture, all_but_first, list}]),
    {D, list_to_integer(Amount)}.

move_x_times({D, Amount}, Rope, TailVisits) ->
    lists:foldl(
        fun(_, {[H|T] = Rope2, TailVisits2}) ->
            Rope3 =
                case T of
                    [] ->
                        [cartesian_step(D, H)] ++ [{0, 0}];
                    _ ->
                        [cartesian_step(D, H)] ++ T
                end,
            [NewH|T3] = Rope3,
            Rope4 =
                [NewH] ++
                rest_of_tail(D, NewH, T3, get_last(T)),
            io:format("First Rope ~p Rope ~p move ~p new rope ~p\n", [Rope2, Rope3, [D], Rope4]),
            TailVisits3 = sets:add_element(lists:last(Rope4), TailVisits2),
            {Rope4, TailVisits3}
        end,
        {Rope, TailVisits},
        lists:seq(1, Amount)
    ).

get_last([]) ->
    [];
get_last(T) ->
    lists:last(T).

rest_of_tail(D, NewHead, RestOfTail, Last) ->
    io:format("~p ~p ~p ~p ~p\n", [?FUNCTION_NAME, [D], NewHead, RestOfTail, Last]),
    rest_of_tail(D, NewHead, RestOfTail, [], Last, false).

rest_of_tail(_D, _, [], Result, Last, false) ->
    lists:reverse(Result);
rest_of_tail(_D, _, [], Result, Last, true) ->
    io:format("ROT1a\n", []),
    lists:reverse(Result)++[Last];
% rest_of_tail(_D, _NewHead, [], Result, Last, TailMoved) ->
%     io:format("ROT2\n", []),
%    lists:reverse(Result);
rest_of_tail(D, NewHead, RestOfTail, Result, Last, TailMoved) ->
    io:format("ROT3 ~p\n", [[D]]),
    [T|Rest] = RestOfTail,
    IsLast= case Rest of
        [] ->
            true;
        _ ->
            false
    end,
    case ST = should_tail_move(NewHead, T) of
        true ->
            NewT = cartesian_step(D,T),
            rest_of_tail(D, NewT, Rest, [NewT|Result], Last, ST andalso IsLast andalso true andalso length(Result) < 8);
        false ->
            rest_of_tail(D, NewHead, Rest, [T|Result], Last, ST  andalso IsLast andalso true andalso length(Result) < 8)
    end.

cartesian_step($U, {X, Y}) ->
    {X, Y+1};
cartesian_step($R, {X, Y}) ->
    {X+1, Y};
cartesian_step($D, {X, Y}) ->
    {X, Y-1};
cartesian_step($L, {X, Y}) ->
    {X-1, Y}.

should_tail_move(MovedHeadPos={X, Y}, TailPos={PX, PY}) ->
    % io:format("should_tail_move ~p ~p\n", [MovedHeadPos, TailPos]),
    Distance = cartesian_distance({PX, PY}, {X, Y}),
    A = (Distance) > 1,
    Distance > 2 andalso throw({too_far, TailPos, MovedHeadPos, Distance, A}),
    A.

































follow_diag_head({TX, TY} = _PrevTailPos, {HX, HY} = _MovedHeadPos) ->
    {inc_tail_or_dec_tail(TX, HX), inc_tail_or_dec_tail(TY, HY)}.

inc_tail_or_dec_tail(T, H) when T < H ->
    T+1;
inc_tail_or_dec_tail(T, _H) ->
    T-1.

cartesian_distance({X1, Y1}, {X2, Y2}) ->
    round(math:sqrt(
        math:pow(X2 - X1, 2) +
        math:pow(Y2 - Y1, 2)
    )).

% cartesian_step($U, {X, Y}) ->
%     {X, Y+1};
% cartesian_step($R, {X, Y}) ->
%     {X+1, Y};
% cartesian_step($D, {X, Y}) ->
%     {X, Y-1};
% cartesian_step($L, {X, Y}) ->
%     {X-1, Y}.

% should_tail_move(MovedHeadPos={X, Y}, TailPos={PX, PY}) ->
%     % io:format("should_tail_move ~p ~p\n", [MovedHeadPos, TailPos]),
%     Distance = cartesian_distance({PX, PY}, {X, Y}),
%     A = (Distance) > 1,
%     Distance > 3 andalso throw({too_far, TailPos, MovedHeadPos, Distance, A}),
%     A.

moved_diag_rel_to_tail({PX, PY} = _PrevTailPos, {X, Y} = _MovedHeadPos) ->
    not (PX =:= X orelse PY =:= Y).

ahead_direction({AheadX, AheadY}, {X, Y}) when AheadX > X andalso AheadY > Y ->
    $U; % Ne
ahead_direction({AheadX, AheadY}, {X, Y}) when AheadX < X andalso AheadY > Y ->
    $U; % Nw
ahead_direction({AheadX, AheadY}, {X, Y}) when AheadX < X andalso AheadY < Y ->
    $D; %% sw
ahead_direction({AheadX, AheadY}, {X, Y}) when AheadX > X andalso AheadY < Y ->
    $D; %% se
ahead_direction({AheadX, AheadY}, {X, Y}) when AheadY > Y ->
    $U;
ahead_direction({AheadX, AheadY}, {X, Y}) when AheadY < Y ->
    $D;
ahead_direction({AheadX, AheadY}, {X, Y}) when AheadX > X ->
    $R;
ahead_direction({AheadX, AheadY}, {X, Y}) when AheadX < X ->
    $L;
ahead_direction({X, Y}, {X, Y}) ->
    undefined.

print_rope(Size, Rope) ->
    io:format("\n~p\n",[Rope]),
    lists:foreach(
        fun(Y) ->
            lists:foreach(
                fun(X) ->
                    % case lists:member({X, Y}, Rope) of
                    case lists:member({X, Y}, Rope) or lists:keyfind({X, Y}, 1, Rope) /= false of
                        true ->
                            io:format("X");
                        false ->
                            case X =:= 0 andalso Y =:= 0 of
                                true ->
                                    io:format("S");
                                false ->
                                    io:format(".")
                            end
                    end
                end,
                lists:seq(-Size, Size)
            ),
            io:format("\n", [])

        end,
        lists:reverse(lists:seq(-Size, Size))
    ),
    io:format("\n").