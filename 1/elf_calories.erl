-module(elf_calories).

-export([
    who_has_the_most_calories/0
]).

who_has_the_most_calories() ->
    {ok, B} = file:read_file("elf_calories.txt"),
    most_calories(each_elf_calories(binary:split(B, <<"\n\n">>, [global]))).

each_elf_calories(EachElfCalories) ->
    lists:map(
        fun(ElfCalories) ->
            elf_snack_count(binary:split(ElfCalories, <<"\n">>, [global]))
        end,
        EachElfCalories
    ).

elf_snack_count(ElfCalories) when is_list(ElfCalories) ->
    lists:foldl(
        fun(Calorie, Total) ->
            binary_to_integer(Calorie)+Total
        end,
        0,
        ElfCalories
    );
elf_snack_count(ElfCalories) when is_binary(ElfCalories) ->
    lists:sum(binary_to_integer(ElfCalories)).

most_calories(EachElfSnackCounts) ->
    lists:max(EachElfSnackCounts).


%% Spoilers: FIrst part answer 71300