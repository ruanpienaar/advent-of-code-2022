-module(supplystacks).

-export([
    run/0,
    get_letter_pos/1
]).

run() ->
    % "CMZ = get_elf_message("test-input.txt").
    % "MCD" = get_elf_message("test-input2.txt").
    get_elf_message("input.txt").

get_elf_message(Filename) ->
    {ok, F} = file:open(Filename, [read, read_ahead]),
    run_instructions_on_stack(
        get_stacks(F),
        get_instructions(F)
    ).

get_stacks(F) ->
    [LastLine | RevStackLines] = get_stack_lines(F, file:read_line(F)),
    StackCount = list_to_integer([lists:last(LastLine--"\n")]),
    {
        StackCount,
        check_each_stack_column(
            create_empty_stacks(),
            lists:reverse(RevStackLines),
            1,
            StackCount
        )
    }.

create_empty_stacks() ->
    lists:foldl(
        fun(C, A) -> A#{ C => queue:new() } end,
        #{},
        lists:seq(1, StackCount)
    ).

% print_stacks(Queues) ->
%     maps:map(
%         fun(Column, Q) ->
%             io:format("~p : ~p\n", [Column, Q])
%         end,
%         Queues
%     ).

check_each_stack_column(Queues, _StackLines, Column, StackCount)
        when Column > StackCount ->
    Queues;
check_each_stack_column(Queues, StackLines, Column, StackCount) ->
    ColumnPos = get_letter_pos(Column),
    check_each_stack_column(
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
        StackLines,
        Column + 1,
        StackCount
    ).

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

run_instructions_on_stack(
        {StackCount, Stacks},
        []
    ) ->
    %_ = print_stacks(Stacks),
    lists:map(
        fun(C) ->
            {{value, V}, _} = queue:out(maps:get(C, Stacks)),
            V
        end,
        lists:seq(1, StackCount)
    );
run_instructions_on_stack(
        {StackCount, Stacks},
        [[Amount, From, To] | Instructions]
    ) ->
    {TakingStack2, Took} =
        lists:foldl(
            fun(_, {TSA, TA}) ->
                {{value, I}, TSA2} = queue:out(TSA),
                {TSA2, [I|TA]}
            end,
            {maps:get(From, Stacks), []},
            lists:seq(1, Amount)
        ),
    run_instructions_on_stack(
        {StackCount, Stacks#{
            From =>
                TakingStack2,
            To =>
                lists:foldl(
                    fun(I, GSA) ->
                        queue:in_r(I, GSA)
                    end,
                    maps:get(To, Stacks),
                    Took
                )
        }},
        Instructions
    ).