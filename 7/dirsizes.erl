-module(dirsizes).

-export([
    run/0,
    all_parent_dirs/1
]).

-define(DISK_TOTAL, 70000000).
-define(MINIMUM, 30000000).

run() ->
    find_smallest_dir_to_delete(
        maps:get(
            sizes,
            aggregate_outputs(
                lists:reverse(
                    read_lines(
                        file:open(
                            % "test-input.txt",
                            "input.txt",
                            [read, read_ahead, binary]
                        )
                    )
                ),
                #{
                    cwd => <<>>,
                    sizes => [{<<"/">>, {dir, [], 0}}]
                }
            )
        )
    ).

find_smallest_dir_to_delete(Sizes) ->
    {value, {<<"/">>, {dir, [], TotalSizeOnDisk}}, Sizes2} = lists:keytake(<<"/">>, 1, Sizes),
    SizeToFreeUp = ?MINIMUM - (?DISK_TOTAL - TotalSizeOnDisk),
    SortedDirs = lists:sort(
        fun({_, {dir, _, A}}, {_, {dir, _, B}}) -> A < B end,
        lists:filter(
            fun
            ({_, {dir, _, Size}}) when Size >= SizeToFreeUp ->
                true;
            (_) ->
                false
            end,
            Sizes2
        )
    ),
    {_, {_, _, SmallestDirSize}} = hd(SortedDirs),
    SmallestDirSize.

read_lines({ok, FPID}) ->
    read_line(FPID, file:read_line(FPID), []).

read_line(_FPID, eof, Sizes) ->
    Sizes;
read_line(FPID, {ok, Line}, Sizes) ->
    read_line(
        FPID,
        file:read_line(FPID),
        parse_line_re(
            re:run(Line, line_re(Line), [{capture, all_but_first, binary}])
        ) ++ Sizes
    ).

line_re(<<"$ ", _/binary>>) ->
    "^\\$ (.*+)$\n";
line_re(<<"dir", _/binary>>) ->
    <<"^dir (.*+)">>;
line_re(_) ->
    "^(\\d+?) (.*)".

parse_line_re({match, [<<"cd ", Dir/binary>>]}) ->
    [{cmd, cd, Dir}];
parse_line_re({match, [<<"ls">>]}) ->
    [{cmd, ls}];
parse_line_re({match, [Filesize, Filename]}) ->
    [{file, binary_to_integer(Filesize), Filename}];
parse_line_re({match, [Dirname]}) ->
    [{dir, Dirname}].

aggregate_outputs([], R) ->
    R;
aggregate_outputs([CmdOrOutput | T], R) ->
    aggregate_outputs(T, interpret_line(CmdOrOutput, R)).

cd_up(PrevCwd) ->
    PrevCwdSplit = binary:split(PrevCwd, <<"/">>, [global, trim_all]),
    NewCwd =
    case lists:reverse(tl(lists:reverse(PrevCwdSplit))) of % how to nicely take of the last item!?!
        [] ->
            <<"/">>;
        XXX ->
            binary:list_to_bin([<<"/">>, filename:join(XXX)])
    end,
    NewCwd.

interpret_line({cmd, cd, <<"..">>}, #{ cwd := PrevCwd } = R) ->
    R#{ cwd => cd_up(PrevCwd) };
interpret_line({cmd, cd, Dir}, #{ cwd := PrevCWD } = R) ->
    R#{ cwd => set_cwd(PrevCWD, Dir) };
interpret_line({cmd, ls}, R) ->
    R;
interpret_line({dir, _Dir} = L, #{ cwd := Cwd, sizes := PrevSizes } = R) ->
    NewSizes = add_new_size_entry(Cwd, L, PrevSizes),
    R#{
        sizes => NewSizes
    };
interpret_line({file, Size, _Filename} = L, #{ cwd := Cwd, sizes := PrevSizes } = R) ->
    % NewSizes = PrevSizes ++ [{filename:join(Cwd, Filename), {file, [Cwd], Size}}],
    NewSizes = add_new_size_entry(Cwd, L, PrevSizes),
    %% Bump CWD size,
    Sizes2 = update_dir_size(Cwd, NewSizes, Size),
    %% them bump parents CWD Size
    ParentDirs = all_parent_dirs(Cwd),
    Sizes3 = lists:foldl(
        fun(ParentWD, SizesAcc) ->
            update_dir_size(ParentWD, SizesAcc, Size)
        end,
        Sizes2,
        ParentDirs
    ),
    R#{
        sizes => Sizes3
    }.

add_new_size_entry(Cwd, Output, Sizes) ->
    {New, _} = Entry = output_to_size_entry(Cwd, Output),
    find_and_add_if_false(New, Entry, Sizes).

output_to_size_entry(Cwd, {dir, Dir}) ->
    {filename:join(Cwd, Dir), {dir, [Cwd], 0}};
output_to_size_entry(Cwd, {file, Size, Filename}) ->
    {filename:join(Cwd, Filename), {file, [Cwd], Size}}.

find_and_add_if_false(V, Entry, Sizes) ->
    add_if_false(Entry, Sizes, lists:keyfind(V, 1, Sizes)).

add_if_false(Entry, Sizes, false) ->
    Sizes ++ [Entry];
add_if_false(_Entry, Sizes, _Dupe) ->
    % the have dirs and files with the same names!!!
    % potential to blow up!
    Sizes.

update_dir_size(Cwd, Sizes, ExtraSize) ->
    {Cwd, {dir, XXX, CwdSize}} = lists:keyfind(Cwd, 1, Sizes),
    lists:keyreplace(Cwd, 1, Sizes, {Cwd, {dir, XXX, CwdSize + ExtraSize}}).

all_parent_dirs(<<"/">>) ->
    [];
all_parent_dirs([]) ->
    [<<"/">>];
all_parent_dirs(Cwd) ->
    split_subtract_and_reconstruct(Cwd).

split_subtract_and_reconstruct(Cwd) ->
    subtract(Cwd, binary:split(Cwd, <<"/">>, [global, trim_all])).

subtract(Cwd, X) when length(X) =:= 1 ->
    all_parent_dirs( X -- [filename:basename(Cwd)] );
subtract(_Cwd, X) ->
    % how to nicely take of the last item!?!
    NewX = filename:join(
        <<"/">>,
        filename:join(
            lists:reverse(tl(lists:reverse(X)))

        )
    ),
    [NewX] ++ all_parent_dirs(NewX).

set_cwd(<<>>, Dir) ->
    Dir;
set_cwd(PrevCWD, Dir) ->
    filename:join(PrevCWD, Dir).