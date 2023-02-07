-module(planck).

% -export([
%     run/0
% ]).

-compile(export_all).

% {ok, _} = c(planck), planck:run().
% Second attempt 6522, too high!


run() ->

    % X = run_instructions(file:open("test-input.txt", [read, read_ahead, binary])),
    % 36 =
    run_instructions(file:open("input.txt", [read, read_ahead, binary])).

run_instructions({ok, FPID}) ->
    run_instructions(FPID, file:read_line(FPID), [{0, 0}, {0, 0}], sets:new()).

get_num_tail_visits(TailVisits) ->
    io:format("TailVisits ~p\n", [ lists:sort( sets:to_list(TailVisits) )]),
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
    io:format("MOVE ~p in ~p\n", [Amount, [D]]),
    YYY=lists:foldl(
        fun(_, {[H|T] = Rope2, TailVisits2}) ->
            %Last2 = lists:last(Rope2),
            Last2 = undefined,
            Rope3 = rest_of_tail(D, H, T, get_last(T)),
            Last3 = lists:last(Rope3),
            io:format("last ~p ~p\n", [Last2, Last3]),
            %TailVisits3 = sets:add_element(Last2, TailVisits2),
            TailVisits4 = sets:add_element(Last3, TailVisits2),
            % print_rope(30, Rope3),
            io:format("rope ~p\n", [Rope3]),
            {Rope3, TailVisits4}
        end,
        {Rope, TailVisits},
        lists:seq(1, Amount)
    ),
    {LRP, NTV} = YYY,
    % NTV2 = sets:add_element(lists:last(LRP), NTV),
    _ = get_num_tail_visits(NTV),
    io:format("-------------------------------------------------------------\n"),
    % {LRP,NTV2}.
    YYY.

get_last([]) ->
    [];
get_last(T) ->
    lists:last(T).

rest_of_tail(D, PrevHead, RestOfTail, Last) ->
    MovedPrevHead = cartesian_step(D, PrevHead),
    % io:format("~p ~p ~p ~p ~p\n", [?FUNCTION_NAME, [D], PrevHead, RestOfTail, Last]),
    rest_of_tail(D, MovedPrevHead, RestOfTail, [MovedPrevHead], Last, false).

rest_of_tail(_D, _, [], Result, Last, false) ->
    % io:format("ROT1 B !!! ----- >>>> Add last ~p\n ! \n", [Last]),
    lists:reverse(Result);
rest_of_tail(_D, _, [], Result, Last, true) ->
    % io:format("ROT1 A !!! ----- >>>> Add last ~p\n ! \n", [Last]),
    lists:reverse(Result)++[Last];
% rest_of_tail(_D, _NewHead, [], Result, Last, TailMoved) ->
%     io:format("ROT2\n", []),
%    lists:reverse(Result);

% Move head in here!
rest_of_tail(D, MovedPrevHead, RestOfTail, Result, Last, TailMoved) ->
    % io:format("\nROT3 ~p\n", [[[D], MovedPrevHead, RestOfTail, Result, Last, TailMoved]]),
    % MovedPrevHead = cartesian_step(D, PrevHead),
    % io:format("MovedPrevHead ~p\n", [MovedPrevHead]),
    [RestOfTailHead|RestOfRestOfTail] = RestOfTail,
    IsLast = case RestOfRestOfTail of
        [] ->
            true;
        _ ->
            false
    end,
    MovedHeadPos = cartesian_step(D, RestOfTailHead),
    % We're comparing NewHEAD( was first of prevtail ) with current head
    case should_tail_move(MovedPrevHead, RestOfTailHead) of
        true ->
            % io:format("Should tail move - TRUE ~p \n", [[MovedPrevHead, RestOfTailHead]]),
            % io:format("moved_diag_rel_to_tail(~p, ~p)\n", [RestOfTailHead, MovedPrevHead]),
            NewT = case moved_diag_rel_to_tail(RestOfTailHead, MovedPrevHead) of
                true ->
                    MovedDiag = follow_diag_head(RestOfTailHead, MovedPrevHead),
                    % io:format("follow_diag_head(~p, ~p) -> ~p\n", [RestOfTailHead, MovedPrevHead, MovedDiag]),
                    % io:format("Move Diag ~p ~p -> ~p\n", [RestOfTailHead, MovedHeadPos, MovedDiag]),
                    MovedDiag;
                false ->
                    % io:format("Move straight\n", []),
                    MovedHeadPos
            end,
            % Result2 = [MovedPrevHead|Result],
            % Result3 = [NewT|Result2],

            Result3 = [NewT|Result],
                % case Result of
                %     [] ->
                %         [NewT, MovedPrevHead];
                %     _ ->
                %         [NewT|Result]
                % end,
            % Should true
            rest_of_tail(D, NewT, RestOfRestOfTail, Result3, Last, true andalso IsLast andalso true andalso length(Result) < 9);
        false ->
            % io:format("Should tail move - FALSE ~p \n", [[MovedPrevHead, RestOfTailHead]]),
            Result3 = [RestOfTailHead|Result],
                % case Result of
                %     [] ->
                %         [RestOfTailHead, MovedPrevHead];
                %     _ ->
                %         [RestOfTailHead|Result]
                % end,
            % Should false
            rest_of_tail(D, RestOfTailHead, RestOfRestOfTail, Result3, Last, false  andalso IsLast andalso true andalso length(Result) < 8)
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
    Distance > 3 andalso throw({too_far, TailPos, MovedHeadPos, Distance, A}),
    A.

cartesian_distance({X1, Y1}, {X2, Y2}) ->
    round(math:sqrt(
        math:pow(X2 - X1, 2) +
        math:pow(Y2 - Y1, 2)
    )).

follow_diag_head({TX, TY} = _PrevTailPos, {HX, HY} = _MovedHeadPos) ->
    {inc_tail_or_dec_tail(TX, HX), inc_tail_or_dec_tail(TY, HY)}.

inc_tail_or_dec_tail(T, H) when T < H ->
    T+1;
inc_tail_or_dec_tail(T, _H) ->
    T-1.































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