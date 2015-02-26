% Copyright 2015 Eric Butler, Adam M. Smith, Erik Andersen.

%% guess if piece is included in puzzle
%{ included(P) } :- fixed(P).
%{ included(P) } :- free(P).
included(P) :- fixed(P).
included(P) :- free(P).
%% guess if included pieces are placed by player
placed(P) :- fixed(P), included(P).
{ placed(P) } :- free(P), included(P).

% always place at least one target!
:- not 1 { placed(P):type(P,target) }.

%% guess where pieces are located
0 [at_bit(A,P,B)=2**B:bit(B) ] width-1 :- piece(P), axis(A), placed(P).

%% guess piece ports
N { port(P,D,S):dir(D) } N :- piece_ports(P,S,N), N > 0, included(P).

%% forbid overlap of pieces
:- pair(P1,P2), eq_coord(P1,P2,A):axis(A).

%% guess port configurations
sense(in;out).
piece_ports(P,in,Ins) :- type(P,C), ports(C,Ins,Outs).
piece_ports(P,out,Outs) :- type(P,C), ports(C,Ins,Outs).
:- piece(P), dir(D), 2 { port(P,D,S) }. % forbid overlapping input/output ports
:- type(P,bender), opposite(D1,D2), port(P,D1,in), port(P,D2,out). % benders bend!

%% require design goal: every target is powered (solved)
1 { source_power(P,F):available_source_power(F) } 1 :- type(P,source), placed(P).
target_power(P,F) :- type(P,target), absorbs(Z,P,F,D).
target_powered(P)  :- target_power(P,F).
:- type(P,target), placed(P), not target_powered(P).

__level_design(included(P)) :- included(P).
__level_design(placed(P)) :- fixed(P).
__level_design(at_bit(A,P,B)) :- at_bit(A,P,B), fixed(P).
__level_design(port(P,D,S)) :- port(P,D,S).
__level_design(source_power(P,F)) :- source_power(P,F). 
__level_design(target_power(P,F)) :- target_power(P,F).

%% nice layout based on having a focal stage in the middle where the solution is made
#const stage_buffer = 2.
on_stage(P,A) :- placed(P), axis(A), 0+stage_buffer [ at_bit(A,P,B)=2**B:bit(B) ] width-stage_buffer-1.
% blockers float in the middle of the stage
wild_blocker((blk,K)) :- piece((blk,K)), K >= 9.
:- type(P,blocker), not wild_blocker(P), axis(A), not on_stage(P,A).
% sources and targets are out of the middle of the stage
:- type(P,source), not 1 { not on_stage(P,A):axis(A) }.
wild_target((trg,K)) :- piece((trg,K)), K >= 6.
:- type(P,target), not wild_target(P), not 1 { not on_stage(P,A):axis(A) }.
% sources/target on edge must fire/absorb into the center
:- type(P,source), axis(A), not port(P,(A,gt),out), width-stage_buffer-1 [ at_bit(A,P,B)=2**B:bit(B) ] width-1.
:- type(P,source), axis(A), not port(P,(A,lt),out), 0 [ at_bit(A,P,B)=2**B:bit(B) ] 0+stage_buffer.
:- type(P,target), axis(A), not port(P,(A,gt),in), width-stage_buffer-1 [ at_bit(A,P,B)=2**B:bit(B) ] width-1.
:- type(P,target), axis(A), not port(P,(A,lt),in), 0 [ at_bit(A,P,B)=2**B:bit(B) ] 0+stage_buffer.
% unused sources leave their row/col untouched by fixed pieces (looks significant)
unused_source(P) :- type(P,source), placed(P), not 1 { grid_edge(P,P2,D):piece(P2) }.
:- unused_source(P), port(P,(A,_),out), axis(A2), A != A2, fixed(P2), placed(P2), P!=P2, 0 [ at_bit(A2,P,B)=2**B:bit(B), at_bit(A2,P2,B)=-(2**B):bit(B) ] 0.

% every free piece (including distractors) must be portable with someone else
reasonable_input(P2) :- portable(P1,P2,D).
reasonable_output(P1) :- portable(P1,P2,D).
:- free(P), not reasonable_input(P).
:- free(P), not reasonable_output(P).

%% reference solution style policy
edge(P1,P2) :- grid_edge(P1,P2,D).
__compare(edge(P1,P2)) :- edge(P1,P2).
crowded(P1,P2) :- grid_edge(P1,P2,(A,gt)), 1 [ at_bit(A,P1,B)=2**B:bit(B), at_bit(A,P2,B)=-(2**B):bit(B) ] 1.
crowded(P1,P2) :- grid_edge(P1,P2,(A,lt)), 1 [ at_bit(A,P1,B)=-(2**B):bit(B), at_bit(A,P2,B)=2**B:bit(B) ] 1.
solution_crowds :- crowded(P1,P2).
solution_punts :- edge(S,T), type(S,source), type(T,target).
solution_interferes :- unused_source(P), axis(A), free(P2), placed(P2), P!=P2, 0 [ at_bit(A,P,B)=2**B:bit(B), at_bit(A,P2,B)=-(2**B):bit(B) ] 0.
shine(P) :- emits(Z,P,F).
solution_avoids :- 3 [ not shine(P):free(P) ].
__reference_styled :-
  not solution_avoids, % leaves too many unused (distractors)
  not solution_crowds, % crowds two beam-linked pieces so beam doesn't show
  not solution_punts, % allows a target to be satisfied directly by source
  not solution_interferes. % comes into conact with an unused source beam

#begin_lua
print([[
level_design(A) :- rule(pos(atom(__level_design(A))),_).
bot :- level_design(A), true(atom(A)), not hold(atom(A)).
bot :- level_design(A), fail(atom(A)), hold(atom(A)).
compare(A) :- rule(pos(atom(__compare(A))),_).
same(A) :- compare(A), true(atom(A)), hold(atom(A)).
same(A) :- compare(A), fail(atom(A)), not hold(atom(A)).
bot :- same(A):compare(A).
:- not bot.
:- not hold(atom(__reference_styled)).
_hold(atom(A)) :- hold(atom(A)).
#hide.
#show _hold/1.
]])
#end_lua.
