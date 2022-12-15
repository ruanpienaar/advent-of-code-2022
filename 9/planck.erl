-module(planck).

-export([
    run/0
]).

run() ->
    {ok, FPID} =
        file:open(
            "input.txt",
            % "test-input.txt",
            [read, read_ahead, binary]
        ),
    % 13 =
    run_instructions(FPID).

run_instructions(FPID) ->
    run_instructions(FPID, file:read_line(FPID), {{0, 0}, {0, 0}, sets:new()}).

run_instructions(_FPID, eof, {TailPos, HeadPos, TailVisits}) ->
    io:format("TailPos ~p HeadPos : ~p\n", [TailPos, HeadPos]),
    sets:size(TailVisits);
run_instructions(FPID, {ok, Line}, LocData) ->

    run_instructions(
        FPID,
        file:read_line(FPID),
        step_head_and_tail(LocData, line_to_instruction(Line))
    ).
line_to_instruction(Line) ->
    {match, [[Direction], Amount]} = re:run(Line, <<"^([U|R|D|L]) (\\d+)">>, [{capture, all_but_first, list}]),
    {Direction, list_to_integer(Amount)}.

step_head_and_tail({TailPos, HeadPos, TailVisits}, {Direction, Amount}) ->
    XX = lists:foldl(
        fun(_, {TailPosAcc, HeadPosAcc, TailVisitsAcc}) ->
            HeadPosAcc2 = cartesian_step(Direction, HeadPosAcc),
            % io:format("Step Head To ~p\n", [HeadPosAcc2]),
            TailPosAcc2 = tail_move(Direction, TailPosAcc, HeadPosAcc, HeadPosAcc2),
            TailVisitsAcc2 = sets:add_element(TailPosAcc2, TailVisitsAcc),
            {TailPosAcc2, HeadPosAcc2, TailVisitsAcc2}
        end,
        {TailPos, HeadPos, TailVisits},
        lists:seq(1, Amount)
    ),
    {TailPos2, HeadPos2, TailVisits2} = XX,
    io:format(
        "Step ~p ~p. H~p T~p AFTER H~p T~p V~p\n",
        [[Direction], Amount, HeadPos, TailPos, HeadPos2, TailPos2, sets:size(TailVisits2)]
    ),
    io:format("---\n", []),
    XX.

cartesian_step($U, {X, Y}) ->
    {X, Y+1};
cartesian_step($R, {X, Y}) ->
    {X+1, Y};
cartesian_step($D, {X, Y}) ->
    {X, Y-1};
cartesian_step($L, {X, Y}) ->
    {X-1, Y}.

% Prev & current head pos,
% so we can infur diag/not.
tail_move(Direction, PrevTailPos, _PrevHeadPos, MovedHeadPos) ->
    move_tail_move(
        Direction,
        PrevTailPos,
        MovedHeadPos,
        should_tail_move(PrevTailPos, MovedHeadPos)
    ).

move_tail_move(Direction, PrevTailPos, MovedHeadPos, true) ->
    case moved_diag_rel_to_tail(PrevTailPos, MovedHeadPos) of
        true ->
            follow_diag_head(Direction, PrevTailPos, MovedHeadPos);
        false ->
            cartesian_step(Direction, PrevTailPos)
    end;
move_tail_move(_Direction, PrevTailPos, _MovedHeadPos, false) ->
    PrevTailPos.

follow_diag_head(_, {TX, TY} = _PrevTailPos, {HX, HY} = _MovedHeadPos) ->
        NewTY =
        case TY < HY of
            true ->
                TY+1;
            false ->
                TY-1
        end,
        NewTX =
        case TX < HX of
            true ->
                TX+1;
            false ->
                TX-1
        end,
    {NewTX, NewTY}.

should_tail_move(TailPos={PX, PY}, MovedHeadPos={X, Y}) ->
    Distance = round(math:sqrt(
        math:pow(PX - X, 2) +
        math:pow(PY - Y, 2)
    )),
    A = (Distance) > 1,
    Distance > 2 andalso throw({too_far, TailPos, MovedHeadPos, Distance, A}),
    A.

moved_diag_rel_to_tail({PX, PY} = _PrevTailPos, {X, Y} = _MovedHeadPos) ->
    not (PX =:= X orelse PY =:= Y).
