-module(elf_calories).

-export([
    who_has_the_most_calories/0
]).

who_has_the_most_calories() ->
    {ok, B} = file:read_file("elf_calories.txt"),
    top_x_calorie_count(
        _X=3,
        each_elf_calories_sorted_desc(binary:split(B, <<"\n\n">>, [global]))
    ).

each_elf_calories_sorted_desc(EachElfCalories) ->
    lists:sort(
        fun(A, B) ->
            A > B
        end,
        lists:map(
            fun(ElfCalories) ->
                elf_snack_count(binary:split(ElfCalories, <<"\n">>, [global]))
            end,
            EachElfCalories
        )
    ).

elf_snack_count(ElfCalories) when is_list(ElfCalories) ->
    lists:foldl(
        fun(Calorie, Total) ->
            binary_to_integer(Calorie)+Total
        end,
        0,
        ElfCalories
    ).

top_x_calorie_count(X, DescEachElfSnackCounts) when X > 0 ->
    most_calories(X, DescEachElfSnackCounts).

most_calories(0, _DescEachElfSnackCounts) ->
    0;
most_calories(X, DescEachElfSnackCounts) ->
    lists:nth(X, DescEachElfSnackCounts) + most_calories(X-1, DescEachElfSnackCounts).


















%% Spoilers:
%% Part1: answer 71300
%% Part2: answer 209691
