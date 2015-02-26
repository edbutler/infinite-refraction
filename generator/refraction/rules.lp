% Copyright 2015 Eric Butler, Adam M. Smith, Erik Andersen.

#const dimensions = 2.
#const width = 10.

width(width).
dimensions(dimensions).

%% fixed pieces are designer placed, free pieces are player placed
% (assumes piece/1 and type/2 are defined by problem instance)
fixed(P) :- piece(P), 1 { type(P,source;target;blocker) }.
free(P) :- piece(P), not fixed(P).

% piece i/o port counts by type
ports(source,0,1).
ports(splitter2,1,2).
ports(splitter3,1,3).
ports(combiner2,2,1).
ports(combiner3,3,1).
ports(target,1,0).
ports(bender,1,1).

%% define spatial grid
ineq(lt;gt).
axis(0..dimensions-1).
dir((A,R)) :- axis(A), ineq(R).
orthogonal((A1,R1),(A2,R2)) :- dir((A1,R1)), dir((A2,R2)), A1 != A2.
opposite((A,R1),(A,R2)) :- axis(A), ineq(R1;R2), R1 != R2.

%% guess piece position in each dimension
#begin_lua function ceil_lg(x) return math.ceil(math.log(x)/math.log(2)) end #end_lua.
bit(0..@ceil_lg(width)-1).
top_bit(@ceil_lg(width)-1).

%% deduce relations, projected onto each axis (defined for P1 < P2)
pair(P1,P2) :- placed(P1;P2), P1 < P2.

bits_eq_downto(A,P1,P2,T+1) :- axis(A), pair(P1,P2), top_bit(T). % everyone agrees in high bits
bits_eq_downto(A,P1,P2,B) :- bit(B), bits_eq_downto(A,P1,P2,B+1), not 1 { at_bit(A,P1;P2,B) } 1.
eq_coord(P1,P2,A) :- bits_eq_downto(A,P1,P2,0).
lt_coord(P1,P2,A) :- bit(B), not at_bit(A,P1,B), at_bit(A,P2,B), bits_eq_downto(A,P1,P2,B+1).
gt_coord(P1,P2,A) :- bit(B), at_bit(A,P1,B), not at_bit(A,P2,B), bits_eq_downto(A,P1,P2,B+1).

%% deduce relative orientations
relative_dir(P1,P2,(A,lt)) :-
  pair(P1,P2),
  axis(A),
  lt_coord(P1,P2,A),
  eq_coord(P1,P2,Ai):axis(Ai):Ai!=A.

relative_dir(P2,P1,(A,lt)) :- % P2 > P1
  pair(P1,P2),
  axis(A),
  gt_coord(P1,P2,A),
  eq_coord(P1,P2,Ai):axis(Ai):Ai!=A.

relative_dir(P1,P2,(A,gt)) :- relative_dir(P2,P1,(A,lt)).

%% deduce pairs with compatible ports
portable(P1,P2,Do) :- port(P1,Do,out), port(P2,Di,in), opposite(Do,Di).

%% deduce blocked portable directions
blocked(P1,P2,D) :- portable(P1,P2,D), relative_dir(P1,P,D ;; P,P2,D).

%% deduce unblocked portable edges
grid_edge(P1,P2,D) :- portable(P1,P2,D), relative_dir(P1,P2,D), not blocked(P1,P2,D).

%% deduce beam flow (recursively)
propagation_time(0..N) :- N = #count { free(P) }.

%% absorption from emission (after time delay)
absorbs(Z+1,P2,F,Di) :-
  emits(Z,P1,F),
  grid_edge(P1,P2,Do),
  opposite(Di,Do),
  propagation_time(Z).

%% emission (from absorption)
emits(0,P,F) :- source_power(P,F).
emits(Z,P,F) :- type(P,bender), absorbs(Z,P,F,D).
emits(Z,P,F2) :- type(P,splitter2), splitter2(F1,F2), absorbs(Z,P,F1,D).
emits(Z,P,F2) :- type(P,splitter3), splitter3(F1,F2), absorbs(Z,P,F1,D).
#begin_lua function max(a,b) return math.max(a,b) end #end_lua.
emits(@max(Z1,Z2),P,F3) :-
  type(P,combiner2),
  combiner2(F1,F2,F3),
  absorbs(Z1,P,F1,Di1),
  absorbs(Z2,P,F2,Di2),
  Di1 != Di2.
%emits(@max(Z1,@max(Z2,Z3)),P,F4) :-
%  type(P,combiner3),
%  combiner3(F1,F2,F3,F4),
%  absorbs(Z1,P,F1,Di1),
%  absorbs(Z2,P,F2,Di2),
%  absorbs(Z3,P,F3,Di3),
%  Di1 != Di2,
%  Di2 != Di3,
%  Di1 != Di3.

