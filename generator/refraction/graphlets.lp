% Copyright 2015 Eric Butler, Adam M. Smith, Erik Andersen.

#const unitcost = 1.

#const c_splitter = 3.
#const c_blocker = 4.
#const c_source2 = 6.
#const c_bender4 = 5.
#const c_distractor = 7.

#begin_lua
  function sorted(term)
    local args = term:args()
    table.sort(args, function(a,b) return tostring(a) < tostring(b) end)
    return Val.new(Val.FUNC,args)
  end
#end_lua.

grid_edge(P,Q) :- grid_edge(P,Q,_).
value(V) :- source_power(_,V).
value(V) :- target_power(_,V).

used(P;Q) :- grid_edge(P,Q).
movable(bender;splitter2;splitter3;combiner2;combiner3).
movable(bender,bender).
movable(splitter2,splitter).
movable(splitter3,splitter).
movable(combiner2,combiner).
movable(combiner3,combiner).

%% now make some graphlets

%% first output mathless graphlets

% "Movable Piece Type"
mpt(P, Label) :- used(P), type(P, Type), movable(Type,Label).

distractor(P) :- free(P), not used(P).
graphlet((_distractors,2..N),unitcost) :- N = #count { distractor(P) }.
graphlet((_distractors,1),c_distractor) :- 1 { distractor(P) }.

graphlet(@sorted((_type_edge,L1,L2)),unitcost) :- grid_edge(N1,N2), mpt(N1,L1), mpt(N2,L2).

graphlet(@sorted((_type_chain,L1,L2,L3)),unitcost) :-
    mpt(N1,L1),mpt(N2,L2),mpt(N3,L3),
    grid_edge(N1,N2),
    grid_edge(N2,N3).

graphlet(@sorted((_type_cable,L1,L2,L3,L4)),unitcost) :-
    mpt(N1,L1),mpt(N2,L2),mpt(N3,L3), mpt(N4,L4),
    grid_edge(N1,N2),
    grid_edge(N2,N3),
    grid_edge(N3,N4).

%% rules for counting number of pieces

graphlet((_num_source,1),unitcost) :-       1 { type(P, source) }.
graphlet((_num_source,2),c_source2) :-     2 { type(P, source) }.
graphlet((_num_source,3..N),unitcost) :-    N = #count { type(P, source) }.
graphlet((_num_target,1..N),unitcost) :-    N = #count { type(P, target) }.
graphlet((_num_bender,1),unitcost) :-       1 { type(P, bender) }.
graphlet((_num_bender,2),unitcost) :-       2 { type(P, bender) }.
graphlet((_num_bender,3),unitcost) :-       3 { type(P, bender) }.
graphlet((_num_bender,4),c_bender4) :-       4 { type(P, bender) }.
graphlet((_num_bender,5..N),unitcost) :-    N = #count { type(P, bender) }.
graphlet((_num_splitter,1),c_splitter) :-   1 { type(P, splitter2;splitter3) }.
graphlet((_num_splitter,2..N),unitcost) :-  N = #count { type(P, splitter2;splitter3) }.
graphlet((_num_splitter3,1..N),unitcost) :- N = #count { type(P, splitter3) }.
graphlet((_has_blockers),c_blocker) :- type(P,blocker).

%graphlet((_num_unused_source),unitcost) :- not used(P), type(P, source) .

fraction((N,D)) :- value((N,D)), N #mod D != 0.
basic((1,1)).
basic((1,2)).
basic((1,3)).
nonbasic(F) :- fraction(F), not basic(F).

fraction_label(V,value) :- value(V).
fraction_label(V,fraction) :- fraction(V).
fraction_label(V,nonbasic) :- nonbasic(V).
fraction_label(V,nonunit) :- nonunit(V).

%% now some graphlets about the fractions on sources/targets

graphlet((_source_power,L),unitcost) :- source_power(P,V), fraction_label(V,L).

source_power(V) :- source_power(_,V).
target_power(V) :- target_power(_,V).

%graphlet((_source_powers,1..N),unitcost) :- N = #count{source_power(V)}.
%graphlet((_target_powers,1..N),unitcost) :- N = #count{target_power(V)}.

%% now math graphs

math_connected(P1, P2) :-
  grid_edge(P1, P2),
  not type(P1,bender).

math_connected(P1, P2) :-
    math_connected(P1, P3),
    grid_edge(P3, P2),
    type(P3, bender).

math_edge(P1,P2) :- math_connected(P1,P2), not type(P2, bender).


graphlet(@sorted((_math_edge,LL1,LL2)),unitcost) :-
    math_edge(P1,P2),
    type(P1,L1), type(P2,L2),
    movable(L1,LL1), movable(L2,LL2).

graphlet(@sorted((_math_branch,LL1,LL2,LL3)),unitcost) :-
    type(N1,L1), type(N2,L2), type(N3,L3),
    movable(L1,LL1), movable(L2,LL2), movable(L3,LL3),
    math_edge(N1,N2), math_edge(N1,N3),
    N2 < N3.

graphlet(@sorted((_math_chain,LL1,LL2,LL3)),unitcost) :-
    type(N1,L1), type(N2,L2), type(N3,L3),
    movable(L1,LL1), movable(L2,LL2), movable(L3,LL3),
    math_edge(N1,N2), math_edge(N2,N3).

graphlet(@sorted((_math_cable,LL1,LL2,LL3,LL4)),unitcost) :-
    type(N1,L1), type(N2,L2), type(N3,L3), type(N4,L4),
    movable(L1,LL1), movable(L2,LL2), movable(L3,LL3), movable(L4,LL4),
    math_edge(N1,N2), math_edge(N2,N3), math_edge(N3,N4).

#hide.
#show graphlet/2.

