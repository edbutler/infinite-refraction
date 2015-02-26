% Copyright 2015 Eric Butler, Adam M. Smith, Erik Andersen.

%% extracts level/1 rules into top-level rules exactly, so pieces will be at the same location, etc. as they are in the level's example solution.

% create pieces based on ones in file
piece(P) :- level(type(P, _)).
placed(P) :- piece(P).
included(P) :- piece(P).
type(P, T) :- level(type(P, T)).

% constrain everything about the level to be the default solution, including free piece locations
port(P,D,S) :- level(port(P,D,S)).
at_bit(A,P,B) :- level(at_bit(A,P,B)).
source_power(P,V) :- level(source_power(P,V)).
target_power(P,V) :- level(target_power(P,V)).

