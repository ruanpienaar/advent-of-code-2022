-module(cleanup).

-export([run/0]).

run() ->
    {ok, FPID} = file:open("input.txt", [read, read_ahead, binary]),
    check_elf_pair_assignments(FPID, file:read_line(FPID)).

check_elf_pair_assignments(_FPID, eof) ->
    0;
check_elf_pair_assignments(FPID, {ok, Line}) ->
    check_if_elf_pair_overlap(split_and_transform_line_input(Line)) +
    check_elf_pair_assignments(FPID, file:read_line(FPID)).

split_and_transform_line_input(Line) ->
    lists:map(
        fun(Str) -> binary_to_integer(Str) end,
        binary:split(Line, input_delimiters(), [global, trim_all])
    ).

input_delimiters() ->
    [<<"-">>, <<",">>, <<"\n">>].

% Elf1 check
check_if_elf_pair_overlap([Elf1Start, Elf1End, Elf2Start, Elf2End])
        when Elf1Start =< Elf2Start andalso
             Elf1End >= Elf2End ->
    1;
%% Elf2 check
check_if_elf_pair_overlap([Elf1Start, Elf1End, Elf2Start, Elf2End])
        when Elf2Start =< Elf1Start andalso
             Elf2End >= Elf1End ->
    1;
check_if_elf_pair_overlap([Elf1Start, Elf1End, Elf2Start, Elf2End]) ->
    check_if_elf_single_space_overlap([Elf1Start, Elf1End, Elf2Start, Elf2End]).

check_if_elf_single_space_overlap([Elf1Start, Elf1End, Elf2Start, Elf2End]) ->
    does_overlap(
        not sets:is_empty(
            sets:intersection(
                sets:from_list(lists:seq(Elf1Start, Elf1End)),
                sets:from_list(lists:seq(Elf2Start, Elf2End))
            )
        )
    ).

does_overlap(true) ->
    1;
does_overlap(false) ->
    0.
