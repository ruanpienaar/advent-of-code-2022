-module(planck).

-export([
    run/0,
    ahead_direction/2,
    print_rope/2
]).

% {ok, _} = c(planck), planck:run().
% Second attempt 6522, too high!


run() ->
    36 =
    % X = run_instructions(file:open("test-input.txt", [read, read_ahead, binary])),
    X = run_instructions(file:open("test-input2.txt", [read, read_ahead, binary])),
    io:format("~p\n", [X]).

run_instructions({ok, FPID}) ->
    run_instructions(FPID, file:read_line(FPID), [{{0, 0}, undefined}, {{0, 0}, undefined}], sets:new()).

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
    {match, [[Direction], Amount]} =
        re:run(Line, <<"^([U|R|D|L]) (\\d+)">>, [{capture, all_but_first, list}]),
    {Direction, list_to_integer(Amount)}.

%% Moving R20 -> X20Y0

% We could keep track of last tail pos?
% [{2,0},{1,0},{0,0}]

% If adding one:
% [{3,0},{2,0},{1,0}]

% Take last and add:
% [{3,0},{2,0},{1,0}] ++ [{0,0}]

% [{0, 0}, {0, 0}] false
% [{1, 0}, {0, 0}] false
% [{2, 0}, {1, 0}] true     ++ [{0,0}]
% [{3, 0}, {2, 0}, true     {1, 0}] ++ [{0,0}]
% [{4, 0}, {3, 0}, true     {2, 0}, {1, 0}] ++ [{0,0}]
% [{5, 0}, {4, 0}, true     {3, 0}, {2, 0}, {1, 0}] ++ [{0,0}]
% [{6, 0}, {5, 0}, true     {4, 0}, {3, 0}, {2, 0}, {1, 0}] ++ [{0,0}]
% [{7, 0}, {6, 0}, true     {5, 0}, {4, 0}, {3, 0}, {2, 0}, {1, 0}] ++ [{0,0}]
% [{8, 0}, {7, 0}, true     {6, 0}, {5, 0}, {4, 0}, {3, 0}, {2, 0}, {1, 0}] ++ [{0,0}]
% [{9, 0}, {8, 0}, true     {7, 0}, {6, 0}, {5, 0}, {4, 0}, {3, 0}, {2, 0}, {1, 0}] ++ [{0,0}]
%
% Stop appending and move LAST POS!
% [{10, 0}, {8, 0}, {7, 0}, {6, 0}, {5, 0}, {4, 0}, {3, 0}, {2, 0}, {1, 0}, {0, 0}]
%
% ...
% ...
% [{19,0},{18,0},{17,0},{16,0},{15,0},{14,0},{13,0},{12,0},{11,0},{10, 0}]
% [{20,0},{19,0},{18,0},{17,0},{16,0},{15,0},{14,0},{13,0},{12,0},{11,0}]

% if length(Rope) > 9, stop adding and move each link!

move_x_times({Direction, Amount}, Rope, TailVisits) ->
    io:format("BEFORE ~p\n", [Rope]),
    io:format("MOVE => ~p AMOUNT => ~p\n", [[Direction], Amount]),
    Return = {RopeRR, _} =
    lists:foldl(
        fun(_, { [{H, _}|T] = Rope2, TailVisits2}) ->
            % io:format("Rope2 ~p\n", [Rope2]),
            LastPos = lists:last(Rope2),
            Rope3 = move(Direction, [{cartesian_step(Direction, H), Direction}|T], LastPos, length(Rope2)),
            print_rope(50, Rope3),
            % TailVisits3 = lists:foldl(fun({Pos, _}, TailVisitsAcc) -> sets:add_element(Pos, TailVisitsAcc) end, TailVisits2, Rope3),
            {P3, _} = lists:last(Rope3),
            TailVisits3 = sets:add_element(P3, TailVisits2),
            {Rope3, TailVisits3}
        end,
        {Rope, TailVisits},
        lists:seq(1, Amount)
    ),
    io:format("AFTER  ~p\n", [RopeRR]),
    Return.

% [{2,0},{0,0}]
% [{3,0},{1,0}]
move(_Direction, [], _LastPos, RopeLen) ->
    [];
move(Direction, [{Knot, _}], LastPos, RopeLen) when RopeLen =< 9 ->
    % io:format("------>>> ~p ~p \n\n", [Knot, LastPos]),
    [{Knot, Direction}]++[LastPos];
move(Direction, [{Knot, _}], LastPos, RopeLen) when RopeLen =:= 10 ->
    % io:format("------>>> ~p ~p \n\n", [Knot, LastPos]),
    [{Knot, Direction}];
move(Direction3, [{MovedHead, _}, {H, _Direction} = HHH | T] = AlreadyMovedHeadRope, LastPos, RopeLen) ->
    % LinkDirection ( get the direction needed to move to follow link!, not head direction )
    % Direction3 = LinkDirection3,
    AheadDirection =
        case ahead_direction(MovedHead, H) of
            undefined ->
                Direction3;
            XXXXXX ->
                XXXXXX
        end,
    % io:format("Where's my link at? above, next, below? ~p ~p ~p\n", [MovedHead, H, []]),
    % io:format(",,,>>> ~p \n\n", [LastPos]),
    % io:format("Direction3 ~p\n", [[Direction3]]),
    case should_tail_move(MovedHead, H) of
        true ->
            XX = case moved_diag_rel_to_tail(H, MovedHead) of
                true ->
                    % io:format("Follow Diag ~p ~p\n", [H, MovedHead]),
                    follow_diag_head(H, MovedHead);
                false ->
                    cartesian_step(Direction3, H)
            end,
            % io:format("LINK -> (~p)<----(~p)\n", [MovedHead, XX]),
            % [MovedHead] ++ move(Direction3, [cartesian_step(Direction3, H)|T], LastPos, RopeLen);
            % [{MovedHead, Direction3}] ++ move(Direction3, [{XX, Direction3}|T], HHH, RopeLen);
            [{MovedHead, AheadDirection}] ++ move(AheadDirection, [{XX, AheadDirection}|T], HHH, RopeLen);
        false ->
            AlreadyMovedHeadRope
    end.


% R 5

% [
% {{5,0}, R},
% {{4,0}, R},
% {{3,0}, R},
% {{2,0}, R},
% {{1,0}, R},
% {{0,0}, R}
% ]

% ...................................................
% ...................................................
% ...................................................
% .........................XXXXXX....................
% ...................................................
% ...................................................
% ...................................................


% Up 8

% [{5,8},{5,7},{5,6},{5,5},{5,4},{4,4},{3,3},{2,2},{1,1},{0,0}]
% [
% {{5,8}, U},
% {{5,7}, U},
% {{5,6}, U},
% {{5,5}, U},
% {{5,4}, U},
% {{4,4}, U},
% {{3,3}, U},
% {{2,2}, U},
% {{1,1}, R},
% {{0,0}, R}
% ]

% ...................................................
% ...................................................
% ...................................................
% ...................................................
% ...................................................
% ..............................X....................
% ..............................X....................
% ..............................X....................
% ..............................X....................
% .............................XX....................
% ............................X......................
% ...........................X.......................
% ..........................X........................
% .........................X.........................
% ...................................................
% ...................................................
% ...................................................
% ...................................................
% ...................................................
% ...................................................





% MOVE => "L" AMOUNT => 8

% ...................................................
% ...................................................
% ...................................................
% .............................X.....................
% ..............................X....................
% ..............................X....................
% ..............................X....................
% .............................XX....................
% ............................X......................
% ...........................X.......................
% ..........................X........................
% .........................X.........................
% ...................................................
% ...................................................
% ...................................................

% [
% {{4,8}, L},
% {{5,7}, U},
% {{5,6}, U},
% {{5,5}, U},
% {{5,4}, U},
% {{4,4}, U},
% {{3,3}, U},
% {{2,2}, U},
% {{1,1}, U},
% {{0,0}, U}
% ]


























% print_rope(26, NewRope),
% move_x_times({Direction, Amount}, Rope, TailVisits) ->
%     lists:foldl(
%         fun(_, Rope2) ->

%             io:format("Rope ~p\n", [Rope2]),

%             % MoveResponse = move(Direction, Rope2, TailVisits, lists:last(Rope2)),

%             [Head|RestRope] = Rope2,
%             [Tail|RestRestRope] = RestRope,
%             MovedHeadPos = cartesian_step(Direction, Head),
%             io:format("Head ~p Tail ~p MovedHead ~p\n", [Head, Tail, MovedHeadPos]),

%             {X, RestRopeWithFirstTailMoved} =
%                 case should_tail_move(MovedHeadPos, Tail) of
%                     true ->
%                         % MovedTail = cartesian_step(Direction, Tail),
%                         % io:format("First moved tail ~p\n", [MovedTail]),
%                         % {true, [MovedTail|RestRestRope]};
%                         {true, RestRope};
%                     false ->
%                         {false, RestRope}
%                 end,
%             io:format("Should move ~p FullTailWithFirstTailMoved ~p\n", [X, RestRopeWithFirstTailMoved]),

%             RestRopeMoved = move(X, Direction, MovedHeadPos, RestRopeWithFirstTailMoved, Tail, TailVisits, []),
%             Rope3 = [MovedHeadPos|RestRopeMoved],
%             io:format("MoveResponse ~p\n\n", [Rope3]),

%             Rope3
%         end,
%         Rope,
%         lists:seq(1, Amount)
%     ).

% move(false, Direction, MovedHeadPos, [HRest | []], PrevTail, TailVisits, R) ->
%     %% Extend?
%     lists:reverse(R) ++ [HRest];
% move(true, Direction, MovedHeadPos, [HRest | []], PrevTail, TailVisits, R) ->
%     %% Extend?
%     lists:reverse(R) ++ [PrevTail] ++ [HRest];
% move(true, Direction, MovedHeadPos, [HRest | RRest], PrevTail, TailVisits, R) ->
%     [TRest|_] = RRest,
%     HRest2 = cartesian_step(Direction, HRest),
%     TRest2 = cartesian_step(Direction, TRest),
%     % io:format("~p ~p\n", [H, T]),
%     %% xxx
%     % should_tail_move(MovedHeadPos={X, Y}, TailPos={PX, PY})
%     move(true, Direction, MovedHeadPos, RRest, PrevTail, TailVisits, TRest2 ++ HRest2 ++ R);
% move(false, _, _, R, _, _, _) ->
%     R.






% move(_Direction, [], _TailVisits, Last) ->
%     [Last];
% move(Direction, [Head]=Rope, TailVisits, Last) when length(Rope) =< 2 ->
%     % MovedHeadPos = cartesian_step(Direction, Head),
%     Rope++Last;
% move(Direction, [Head|Rest]=Rope, TailVisits, Last) ->
%     io:format("Rope ~p Rest ~p\n", [Rope, Rest]),
%     [Tail|Rest2] = Rest,
%     MovedHeadPos = cartesian_step(Direction, Head),
%     io:format("MovedHeadPos ~p\n", [MovedHeadPos]),
%     case should_tail_move(MovedHeadPos, Tail) of
%         true ->
%             % move all subsequent tail items!!! 5, 4, 3, ...
%             % follow_diag_head(Tail, MovedHeadPos);
%             %% Move tail, and use that as HEAD in the next pass!!!
%             MovedTailPos =
%                 case moved_diag_rel_to_tail(Tail, MovedHeadPos) of
%                     true ->
%                         follow_diag_head(Tail, MovedHeadPos);
%                     false ->
%                         cartesian_step(Direction, Tail)
%                 end,
%             io:format("Tail ~p MovedTailPos ~p\n", [Tail, MovedTailPos]),

%             NestedMove = move(Direction, Rest2, TailVisits, Last),
%             io:format("NestedMove response ~p\n", [NestedMove]),

%             [MovedHeadPos] ++
%             [MovedTailPos] ++
%             NestedMove;
%         false ->
%             [MovedHeadPos|Rest]
%     end.

% extend(Rest2, _Tail) when length(Rest2) > 9 ->
%     Rest2;
% extend(Rest2, Tail) ->
%     % io:format("extend ~p with ~p\n", [Rest2, Tail]),
%     [Tail] ++ Rest2.

































% move(Direction, [], TailVisits, R) ->
%     lists:reverse(R);
% move(Direction, [Last], TailVisits, R) ->
%     lists:reverse(  lists:append([cartesian_step(Direction, Last)], R)  );

% move(Direction, [ Head | Rest ] = Rope, TailVisits, R) ->
%     [Tail | _] = Rest,
%     MovedHeadPos = cartesian_step(Direction, Head),
%     recurse_tail(
%         should_tail_move(MovedHeadPos, Tail),
%         Direction,
%         MovedHeadPos,
%         Rest,
%         TailVisits,
%         R
%     ).

% recurse_tail(false, Direction, _MovedHeadPos, [], TailVisits, R) ->
%     [];
% recurse_tail(true, Direction, _MovedHeadPos, [], TailVisits, R) ->
%     % extend!
%     [{x, y}];
% %            true, R,         {3, 0},       {1,0},{0,0},            TV,         []
% recurse_tail(true, Direction, MovedHeadPos, [Tail] = Rope, TailVisits, R) ->
%     NewTailPos =
%         case moved_diag_rel_to_tail(Tail, MovedHeadPos) of
%             true ->
%                 follow_diag_head(Tail, MovedHeadPos);
%             false ->
%                 cartesian_step(Direction, Tail)
%         end,
%     move(Direction, [], TailVisits, [NewTailPos] ++ R);
% recurse_tail(true, Direction, MovedHeadPos, [Tail | Rest] = Rope, TailVisits, R) ->
%     % {2, 0}
%     NewTailPos =
%         case moved_diag_rel_to_tail(Tail, MovedHeadPos) of
%             true ->
%                 follow_diag_head(Tail, MovedHeadPos);
%             false ->
%                 cartesian_step(Direction, Tail)
%         end,
%     % Where do we store NewTailPos?

%     %    R,         [{0, 0}], TV,     [{2, 0}| []]
%     move(Direction, Rest, TailVisits, [NewTailPos] ++ [MovedHeadPos] ++ R);
% recurse_tail(false, Direction, NewTailPos, [ Head | Rest ] = Rope, TailVisits, R) ->
%     Rope.






















    % case should_tail_move(MovedHeadPos, Tail) of
    %     true ->
    %         ok;
    %     false ->
    %         lists:append([MovedHeadPos, Tail], Rest)
    % end.

    % MovedHeadPos = cartesian_step(Direction, Head),
    % NewRope = move_tails(
    %     should_tail_move(MovedHeadPos, Tail),
    %     Direction,
    %     MovedHeadPos,
    %     % [ Head, Tail | Rest ] = Rope,
    %     Rest,
    %     TailVisits
    % ),
    % move(Direction, Rest, TailVisits, NewRope).


% move_tails(true, Direction, NewHeadPos, [ Head, Tail | Rest ] = Rope, TailVisits) ->
%     %% Get tail-move = X inc/dec & y inc/dec.
%     %% Apply tail-move to rest of tails
%     NewTailPos =
%         case moved_diag_rel_to_tail(Tail, MovedHeadPos) of
%             true ->
%                 follow_diag_head(Tail, MovedHeadPos);
%             false ->
%                 cartesian_step(Direction, Tail)
%         end,

%     lists:foldl(
%         fun(_, Acc) ->
%             Acc
%         end,
%         Rope,
%         Rope
%     ),
% move_tails(false, Direction, NewHeadPos, [ Head, Tail | Rest ] = Rope, TailVisits) ->
%     Rope.



% step_knots([], _, A) ->
%     A;
% step_knots([_H | []], _, A) ->
%     A;
% step_knots([H | [T|_] = R], Instr, A) ->
%     % io:format("perform knot logic on ~p\n", [{H, T}]),
%     #{ rope := _Rope2 } = NewA = step_single_knot(A, Instr),
%     % NewA = A,
%     step_knots(R, Instr, NewA).








% move_tail(true, Direction, MovedHeadPos, #{ rope := [_, Tail | RestTail] } = A) ->
%     Tail2 =
%         case moved_diag_rel_to_tail(Tail, MovedHeadPos) of
%             true ->
%                 follow_diag_head(Tail, MovedHeadPos);
%             false ->
%                 cartesian_step(Direction, Tail)
%         end,
%     % io:format("Move tail, MovedH ~p PREVT ~p NewTail ~p\n", [MovedHeadPos, Tail, Tail2]),
%     TailVisits2 = sets:add_element(Tail, maps:get(tail_visits, A)),
%     TailVisits3 = sets:add_element(Tail2, TailVisits2),
%     RestTail2 = extend_tail([Tail], RestTail),
%     NewRope1 = lists:append([MovedHeadPos, Tail2], RestTail2),
%     A#{
%         rope => NewRope1,
%         tail_visits => TailVisits3
%     };
% move_tail(false, _Direction, MovedHeadPos, #{ rope := [_, Tail | []] } = A) ->
%     % io:format("NOT Move tail, MovedH ~p PREVT ~p\n", [MovedHeadPos, Tail]),
%     % io:format("RestTail ~p\n", [[]]),
%     NewRope1 = lists:append([MovedHeadPos], [Tail]),
%     A#{ rope => NewRope1 };
% move_tail(false, _Direction, MovedHeadPos, #{ rope := [_, Tail | RestTail] } = A) ->
%     % io:format("NOT Move tail, MovedH ~p PREVT ~p\n", [MovedHeadPos, Tail]),
%     % io:format("RestTail ~p\n", [RestTail]),
%     NewRope1 = lists:append([MovedHeadPos, Tail], RestTail),
%     A#{ rope => NewRope1 }.

% extend_tail(Tail, RestRope) when length(RestRope) < 8 ->
%     ExtededTail = lists:append(
%         Tail,
%         RestRope
%     ),
%     % io:format("after tail extend ~p\n", [ExtededTail]),
%     ExtededTail;
% extend_tail(Tail, RestRope) ->
%     % RestRope.
%     ExtededTail = lists:append(
%         Tail,
%         lists:reverse(tl(lists:reverse(RestRope)))
%     ),
%     ExtededTail.

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

moved_diag_rel_to_tail({PX, PY} = _PrevTailPos, {X, Y} = _MovedHeadPos) ->
    not (PX =:= X orelse PY =:= Y).


print_rope(Size, Rope) ->
    io:format("\n~p\n",[Rope]),
    lists:foreach(
        fun(Y) ->

            lists:foreach(
                fun(X) ->
                    % case lists:member({X, Y}, Rope) of
                    case lists:keyfind({X, Y}, 1, Rope) /= false of
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