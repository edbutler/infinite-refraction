% Copyright 2015 Eric Butler, Adam M. Smith, Erik Andersen.

type(P,T) :- level(type(P,T)).
source_power(P,V) :- level(source_power(P,V)).
piece(P) :- type(P,_).
port(P,D,S) :- level(port(P,D,S)).
at_bit(A,P,B) :- level(at_bit(A,P,B)), fixed(P).

%% guess if piece is included in puzzle
included(P) :- fixed(P).
included(P) :- free(P).
%% guess if included pieces are placed by player
placed(P) :- fixed(P), included(P).
{ placed(P) } :- free(P), included(P).

%% guess where FREE pieces are located, FIXED are given by the level
0 [at_bit(A,P,B)=2**B:bit(B) ] width-1 :- free(P), axis(A), placed(P).

%% forbid overlap of pieces
:- pair(P1,P2), eq_coord(P1,P2,A):axis(A).

%% require design goal: every target is powered (solved)
target_power(P,F) :- type(P,target), absorbs(Z,P,F,D).
% HACK need to enforce target_power this way because of the way the code checks that all targets are solved
% could change it, but this way it's closer to the way generate works so possibly easier to understand
:- target_power(P,V1), level(target_power(P,V2)), V1 != V2.

target_powered(P)  :- target_power(P,F).
:- type(P,target), placed(P), not target_powered(P).


