-module(rockpaperscicors).

-export([run/0]).

run() ->
    calculate_round_scores(file:open("input.txt", [read, read_ahead, binary])).

calculate_round_scores({ok, FPID}) ->
    calculte_round_score(FPID, file:read_line(FPID)).

calculte_round_score(_FPID, eof) ->
    0;
calculte_round_score(FPID, {ok, Line}) ->
    {ok, OpponentInput, MyInput} = get_player_inputs(Line),
    OpponentChoice = input_to_shape(OpponentInput),
    MyChoice = input_to_shape(MyInput),
    my_score(
        OpponentChoice,
        MyChoice
    ) +
    shape_score(MyChoice) +
    calculte_round_score(FPID, file:read_line(FPID)).

my_score(Choice, Choice) ->
    score(draw);
my_score(OpponentChoice, MyChoice) ->
    case MyChoice =:= winable_choice(OpponentChoice) of
        true ->
            score(win);
        false ->
            score(lost)
    end.

get_player_inputs(Line) ->
    {ok, binary:at(Line, 0), binary:at(Line, 2)}.

score(lost) ->
    0;
score(draw) ->
    3;
score(win) ->
    6.

winable_choice(rock) ->
    paper;
winable_choice(paper) ->
    scissor;
winable_choice(scissor) ->
    rock.

shape_score(rock) ->
    1;
shape_score(paper) ->
    2;
shape_score(scissor) ->
    3.

input_to_shape(Choice)
        when Choice =:= $A orelse
             Choice =:= $X ->
    rock;
input_to_shape(Choice)
        when Choice =:= $B orelse
             Choice =:= $Y ->
    paper;
input_to_shape(Choice)
        when Choice =:= $C orelse
             Choice =:= $Z ->
    scissor.