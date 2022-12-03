-module(rucksack).

-export([run/0, compare_compartment_items/4]).

run() ->
    {ok, FPID} = file:open("input.txt", [read, read_ahead]),
    group_rucksack(FPID, get_group_rucksacks(FPID)).

group_rucksack(_, [eof, _, _]) ->
    0;
group_rucksack(FPID, [{ok, Line1}, {ok, Line2}, {ok, Line3}]) ->
    shared_items(
        truncate_lf(Line1),
        truncate_lf(Line2),
        truncate_lf(Line3)
    ) +
    group_rucksack(FPID, get_group_rucksacks(FPID)).

truncate_lf(Line) ->
    Line--"\n".

get_group_rucksacks(FPID) ->
    [file:read_line(FPID), file:read_line(FPID), file:read_line(FPID)].

shared_items(Line1, Line2, Line3) ->
    compare_compartment_items(Line1, Line2, Line3, {0, []}).

compare_compartment_items([], _, _, {Total, _}) ->
    Total;
compare_compartment_items([H | T], Line2, Line3, {Total, AllreadyFound}) ->
    compare_compartment_items(
        T,
        Line2,
        Line3,
        case similar_item(H, AllreadyFound, Line2, Line3) of
            false ->
                {Total, AllreadyFound};
            true ->
                {Total + letter_prio(H), [H] ++ AllreadyFound}
        end
    ).

similar_item(H, AllreadyFound, Line2, Line3) ->
    not lists:member(H, AllreadyFound) andalso
    lists:member(H, Line2) andalso lists:member(H, Line3).

letter_prio(UpperCase) when UpperCase >= 65 andalso UpperCase =< 90 ->
    (UpperCase - $A) + 27;
letter_prio(LowerCase) when LowerCase >= 97 andalso LowerCase =< 122 ->
    (LowerCase - $a) + 1.