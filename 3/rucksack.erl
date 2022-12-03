-module(rucksack).

-export([run/0, letter_prio/1]).

% Every item type is identified by a single lowercase or uppercase letter (that is, a and A refer to different types of items).

% priority:
% Lowercase item types a through z have priorities 1 through 26.
% Uppercase item types A through Z have priorities 27 through 52.

% Find the item type that appears in both compartments of each rucksack.
% What is the sum of the priorities of those item types?

run() ->
    {ok, FPID} = file:open("input.txt", [read, read_ahead]),
    each_rucksack(FPID, file:read_line(FPID)).

each_rucksack(_, eof) ->
    0;
each_rucksack(FPID, {ok, Line}) ->
    shared_items(Line--"\n") + each_rucksack(FPID, file:read_line(FPID)).

shared_items(Line) ->
    compare_compartment_items(compartment_props(Line), {0, []}).

compartment_props(Line) ->
    CompartmentLength = length(Line) div 2,
    {Compartment1, Compartment2} = lists:split(CompartmentLength, Line),
    Compartment1Prop = lists:zip(Compartment1, lists:duplicate(CompartmentLength, 0)),
    Compartment2Prop = lists:zip(Compartment2, lists:duplicate(CompartmentLength, 0)),
    {Compartment1Prop, Compartment2Prop}.

compare_compartment_items({[], _}, {Total, _}) ->
    Total;
compare_compartment_items({[{Item, _} | T], Compartment2Prop}, {Total, AllreadyFound}) ->
    compare_compartment_items(
        {T, Compartment2Prop},
        case
            not lists:member(Item, AllreadyFound) andalso
            lists:keyfind(Item, 1, Compartment2Prop) /= false
        of
            false ->
                {Total, AllreadyFound};
            true ->
                {Total + letter_prio(Item), [Item] ++ AllreadyFound}
        end
    ).

letter_prio(UpperCase) when UpperCase >= 65 andalso UpperCase =< 90 ->
    (UpperCase - $A) + 27;
letter_prio(LowerCase) when LowerCase >= 97 andalso LowerCase =< 122 ->
    (LowerCase - $a) + 1.