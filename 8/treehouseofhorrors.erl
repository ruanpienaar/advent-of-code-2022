-module(treehouseofhorrors).

-export([
    run/0,
    get_scenic_score/3
]).

run() ->
    {ok, FPID} =
        file:open(
            "input.txt",
            [read, read_ahead, binary]
        ),
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
    _InnerCount = visible_tree_scan(Matrix, Max, 0).

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

visible_tree_scan(Matrix, Max, HighestScenicScore) ->
    scan(Matrix, {2, 2}, Max, HighestScenicScore).

scan(_Matrix, {_X, Y}, Max, HighestScenicScore) when Y > Max ->
    HighestScenicScore;
scan(Matrix, {X, Y}, Max, HighestScenicScore) when X > Max ->
    scan(Matrix, {2, Y+1}, Max, HighestScenicScore);
scan(Matrix, {X, Y}, Max, HighestScenicScore) ->
    Row = lists:nth(Y, Matrix),
    TreeHeight = lists:nth(X, Row),
    Column =
        lists:map(
            fun(Xmap) -> lists:nth(X, lists:nth(Xmap, Matrix)) end,
            lists:seq(1, Max+1)
        ),
    [Left, Right] = split_and_remove_cell(X, Row),
    [Top, Bottom] = split_and_remove_cell(Y, Column),

    ScenicScore =
        get_scenic_score(TreeHeight, left, Left) *
        get_scenic_score(TreeHeight, right, Right) *
        get_scenic_score(TreeHeight, top, Top) *
        get_scenic_score(TreeHeight, bottom, Bottom),

    NewHighestScenicScore =
        case ScenicScore > HighestScenicScore of
            true ->
                ScenicScore;
            false ->
                HighestScenicScore
        end,
    scan(
        Matrix,
        {X+1, Y},
        Max,
        NewHighestScenicScore
    ).

get_scenic_score(TreeHeight, Direction, DirectionList) ->
    LookingOrder = get_looking_order(Direction, DirectionList),
    looking_distance(TreeHeight, LookingOrder, 0).

looking_distance(TreeHeight, [LookingTreeHeight|_RestTrees], R) when LookingTreeHeight >= TreeHeight ->
    R+1;
looking_distance(TreeHeight, [LookingTreeHeight|RestTrees], R) when LookingTreeHeight < TreeHeight ->
    looking_distance(TreeHeight, RestTrees, R+1);
looking_distance(_TreeHeight, [], R) ->
    R.

get_looking_order(Direction, DirectionList) when Direction =:= left orelse Direction =:= top ->
    lists:reverse(DirectionList);
get_looking_order(Direction, DirectionList) when Direction =:= right orelse Direction =:= bottom ->
    DirectionList.

split_and_remove_cell(SplitAndRemovePos, List) ->
    {_, {Tfel, Thgir}, _} =
        lists:foldl(
            fun
            (_C, {Pos, {LeftAcc, RightAcc}, left}) when Pos =:= SplitAndRemovePos ->
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