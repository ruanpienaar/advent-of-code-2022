-module(supplystacks).

-export([
    run/0,
    get_letter_pos/1
]).

run() ->
    get_elf_message("input.txt").

get_elf_message(Filename) ->
    {ok, F} = file:open(Filename, [read, read_ahead]),
    run_instructions_on_stack(
        get_stacks(F),
        get_instructions(F)
    ).

get_stacks(F) ->
    [LastLine | RevStackLines] = get_stack_lines(F, file:read_line(F)),
    StackLines = lists:reverse(RevStackLines),
    StackCount = list_to_integer([lists:last(LastLine--"\n")]),
    Queues = lists:foldl(
        fun(C, A) ->
            A#{ C => queue:new() }
        end,
        #{},
        lists:seq(1, StackCount)
    ),
    Queues2 =
        check_each_stack_column(
            Queues,
            StackLines,
            1,
            StackCount
        ),
    {
        StackCount,
        Queues2
    }.

check_each_stack_column(Queues, _StackLines, Column, StackCount) when Column > StackCount ->
    Queues;
check_each_stack_column(Queues, StackLines, Column, StackCount) ->
    ColumnPos = get_letter_pos(Column),
    Queues2 =
        lists:foldl(
            fun(Line, AQ) ->
                AQ#{
                    Column =>
                        get_row_column_chars_and_set_row_q(
                            maps:get(Column, AQ),
                            Line,
                            ColumnPos
                        )
                }
            end,
            Queues,
            StackLines
        ),
    check_each_stack_column(Queues2, StackLines, Column + 1, StackCount).

get_letter_pos(Column) ->
    Column * 3 + (Column - 2).

get_row_column_chars_and_set_row_q(ColumnQueue, Line, LetterPos)
        when LetterPos > length(Line) ->
    ColumnQueue;
get_row_column_chars_and_set_row_q(ColumnQueue, Line, LetterPos) ->
    case lists:nth(LetterPos, Line) of
        $ ->
            ColumnQueue;
        Letter ->
            queue:in(Letter, ColumnQueue)
    end.

get_stack_lines(_F, {ok, "\n"}) ->
    [];
get_stack_lines(F, {ok, Line}) ->
    lists:append(get_stack_lines(F, file:read_line(F)), [Line]).

get_instructions(F) ->
    {ok, MP} = re:compile("^move (\\d+?) from (\\d+?) to (\\d+?)"),
    get_instruction_line(MP, F, file:read_line(F)).

get_instruction_line(_MP, _F, eof) ->
    [];
get_instruction_line(MP, F, {ok, Line}) ->
    {match, [MoveAmount, FromStack, ToStack]} =
        re:run(Line, MP, [{capture, all_but_first, list}]),
    lists:append(
        [[
            list_to_integer(MoveAmount),
            list_to_integer(FromStack),
            list_to_integer(ToStack)
        ]],
        get_instruction_line(MP, F, file:read_line(F))
    ).

run_instructions_on_stack({StackCount, Stacks}, []) ->
    lists:map(
        fun(C) ->
            {{value, V}, _} = queue:out(maps:get(C, Stacks)),
            V
        end,
        lists:seq(1, StackCount)
    );
run_instructions_on_stack({StackCount, Stacks}, [[Amount, From, To] | Instructions]) ->
    TakingStack = maps:get(From, Stacks),
    GivingStack = maps:get(To, Stacks),
    {TakingStack2, GvingStack2} =
        lists:foldl(
            fun(_, {TSA, GSA}) ->
                {{value, I}, TSA2} = queue:out(TSA),
                GSA2 = queue:in_r(I, GSA),
                {TSA2, GSA2}
            end,
            {TakingStack, GivingStack},
            lists:seq(1, Amount)
        ),
    Stacks2 = Stacks#{
        From => TakingStack2,
        To => GvingStack2
    },
    run_instructions_on_stack({StackCount, Stacks2}, Instructions).