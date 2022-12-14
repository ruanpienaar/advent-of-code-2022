-module(treehouseofhorrors).

-export([run/0]).

run() ->
    {ok, FPID} =
        file:open(
            % "test-input.txt",
            "input.txt",
            [read, read_ahead, binary]
        ),
    % 21 =
    1672 =
    visible_trees(
        create_matrix(
            FPID,
            file:read_line(FPID),
            [],
            0
        )
    ).

visible_trees(Matrix) ->
    L = length(Matrix),
    Max = L-1,
    EdgeCount = L + (Max) + (Max) + (Max-1), % Sucky!
    InnerCount = visible_tree_scan(Matrix, Max, 0),
    EdgeCount + InnerCount.

create_matrix(_FPID, eof, Matrix, _RowCount) ->
    lists:reverse(Matrix);
create_matrix(FPID, {ok, Line}, Matrix, RowCount) ->
    create_matrix(
        FPID,
        file:read_line(FPID),
        [create_row(Line, [], 0)|Matrix],
        RowCount + 1
    ).

create_row(End, Row, _) when End == <<>> orelse End == <<"\n">> ->
    lists:reverse(Row);
create_row(<<Char/integer, Rest/binary>>, Row, ColCount) ->
    create_row(Rest, [Char-48 | Row] , ColCount+1).

visible_tree_scan(Matrix, Max, VisibleCount) ->
    scan(Matrix, {2, 2}, Max, VisibleCount).

scan(_Matrix, _Pos={X, Y}, Max, VisibleCount) when Y > Max ->
    VisibleCount;
scan(Matrix, _Pos={X, Y}, Max, VisibleCount) when X > Max ->
    scan(Matrix, {2, Y+1}, Max, VisibleCount);
scan(Matrix, Pos={X, Y}, Max, VisibleCount) ->
    Row = lists:nth(Y, Matrix),
    PosValue = lists:nth(X, Row),
    Column =
        lists:map(
            fun(Xmap) -> lists:nth(X, lists:nth(Xmap, Matrix)) end,
            lists:seq(1, Max+1)
        ),
    [Left, Right] = split_and_remove_cell(X, Row),
    [Top, Bottom] = split_and_remove_cell(Y, Column),
    scan(
        Matrix,
        {X+1, Y},
        Max,
        increment(
            PosValue > lists:max(Left) orelse
            PosValue > lists:max(Right) orelse
            PosValue > lists:max(Top) orelse
            PosValue > lists:max(Bottom),
            VisibleCount
        )
    ).

increment(true, VisibleCount) ->
    VisibleCount+1;
increment(false, VisibleCount) ->
    VisibleCount.

split_and_remove_cell(SplitAndRemovePos, List) ->
    {_, {Tfel, Thgir}, _} =
        lists:foldl(
            fun
            (C, {Pos, {LeftAcc, RightAcc}, left}) when Pos =:= SplitAndRemovePos ->
                {Pos+1, {LeftAcc, RightAcc}, right};
            (C, {Pos, {LeftAcc, RightAcc}, Direction}) ->
                {Pos+1, direction_append(Direction, C, {LeftAcc, RightAcc}), Direction}
            end,
            {1, {[], []}, left},
            List
        ),
    [lists:reverse(Tfel), lists:reverse(Thgir)].

direction_append(left, Item, {Left, Right}) ->
    {[Item|Left], Right};
direction_append(right, Item, {Left, Right}) ->
    {Left, [Item|Right]}.