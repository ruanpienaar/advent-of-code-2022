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
    MyChoice = get_my_choice(OpponentChoice, MyInput),
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

losing_choice(paper) ->
    rock;
losing_choice(scissor) ->
    paper;
losing_choice(rock) ->
    scissor.

shape_score(rock) ->
    1;
shape_score(paper) ->
    2;
shape_score(scissor) ->
    3.

input_to_shape($A) ->
    rock;
input_to_shape($B) ->
    paper;
input_to_shape($C) ->
    scissor.

get_my_choice(OpponentChoice, MyInput) ->
    MyInstruction = input_to_decision(MyInput),
    instruction_to_choice(OpponentChoice, MyInstruction).

instruction_to_choice(OpponentChoice, lose) ->
    losing_choice(OpponentChoice);
instruction_to_choice(OpponentChoice, win) ->
    winable_choice(OpponentChoice);
instruction_to_choice(OpponentChoice, draw) ->
    OpponentChoice.

input_to_decision($X) ->
    lose;
input_to_decision($Y) ->
    draw;
input_to_decision($Z) ->
    win.