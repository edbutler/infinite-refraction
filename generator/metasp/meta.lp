%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This file is part of metasp.                                            %
% Copyright (C) 2015  Martin Gebser                                       %
% Copyright (C) 2015  Roland Kaminski                                     %
% Copyright (C) 2015  Torsten Schaub                                      %
%                                                                         %
% metasp is free software: you can redistribute it and/or modify          %
% it under the terms of the GNU General Public License as published by    %
% the Free Software Foundation, either version 3 of the License, or       %
% (at your option) any later version.                                     %
%                                                                         %
% metasp is distributed in the hope that it will be useful,               %
% but WITHOUT ANY WARRANTY; without even the implied warranty of          %
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the           %
% GNU General Public License for more details.                            %
%                                                                         %
% You should have received a copy of the GNU General Public License       %
% along with metasp.  If not, see <http://www.gnu.org/licenses/>.         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Meta-encoding of reified logic programs' answer sets, as obtained via:  %
% $ gringo --reify <inputs>                                               %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% extract body elements

litb(B) :- rule(_,B).
litb(E) :- litb(pos(conjunction(S))), set(S,E).
litb(E) :- eleb(sum(_,S,_)), wlist(S,_,E,_).
litb(E) :- eleb(min(_,S,_)), wlist(S,_,E,_).
litb(E) :- eleb(max(_,S,_)), wlist(S,_,E,_).
% NOTE: avg, even, and odd aggregates are not supported by metaD.lp

eleb(P) :- litb(pos(P)).
eleb(N) :- litb(neg(N)).

% generate answer set from reified rules

hold(conjunction(S)) :- eleb(conjunction(S)),
                hold(P)     : set(S,pos(P)),
            not hold(N)     : set(S,neg(N)).
hold(sum(L,S,U))     :- eleb(sum(L,S,U)),
  L #sum  [     hold(P) = W : wlist(S,Q,pos(P),W),
            not hold(N) = W : wlist(S,Q,neg(N),W) ] U.
hold(min(L,S,U))     :-  eleb(min(L,S,U)),
  L #min  [     hold(P) = W : wlist(S,Q,pos(P),W),
            not hold(N) = W : wlist(S,Q,neg(N),W) ] U.
hold(max(L,S,U))     :-  eleb(max(L,S,U)),
  L #max  [     hold(P) = W : wlist(S,Q,pos(P),W),
            not hold(N) = W : wlist(S,Q,neg(N),W) ] U.
hold(avg(L,S,U))     :-  eleb(avg(L,S,U)),
  L #avg  [     hold(P) = W : wlist(S,Q,pos(P),W),
            not hold(N) = W : wlist(S,Q,neg(N),W) ] U.
hold(even(S))        :-  eleb(even(S)),
    #even [     hold(P) = W : wlist(S,Q,pos(P),W),
            not hold(N) = W : wlist(S,Q,neg(N),W) ].
hold(odd(S))         :-  eleb(odd(S)),
    #odd  [     hold(P) = W : wlist(S,Q,pos(P),W),
            not hold(N) = W : wlist(S,Q,neg(N),W) ].

hold(atom(A))        :- rule(pos(atom(A)),        pos(B)), hold(B).
hold(P) : set(S,pos(P))
                     :- rule(pos(disjunction(S)), pos(B)), hold(B).
L #sum  [     hold(P) = W : wlist(S,Q,pos(P),W),
          not hold(N) = W : wlist(S,Q,neg(N),W) ] U
                     :- rule(pos(sum(L,S,U)),     pos(B)), hold(B).
L #min  [     hold(P) = W : wlist(S,Q,pos(P),W),
          not hold(N) = W : wlist(S,Q,neg(N),W) ] U
                     :- rule(pos(min(L,S,U)),     pos(B)), hold(B).
L #max  [     hold(P) = W : wlist(S,Q,pos(P),W),
          not hold(N) = W : wlist(S,Q,neg(N),W) ] U
                     :- rule(pos(max(L,S,U)),     pos(B)), hold(B).
L #avg  [     hold(P) = W : wlist(S,Q,pos(P),W),
          not hold(N) = W : wlist(S,Q,neg(N),W) ] U
                     :- rule(pos(avg(L,S,U)),     pos(B)), hold(B).
  #even [     hold(P) = W : wlist(S,Q,pos(P),W),
          not hold(N) = W : wlist(S,Q,neg(N),W) ]
                     :- rule(pos(even(S)),        pos(B)), hold(B).
  #odd  [     hold(P) = W : wlist(S,Q,pos(P),W),
          not hold(N) = W : wlist(S,Q,neg(N),W) ]
                     :- rule(pos(odd(S)),         pos(B)), hold(B).
                     :- rule(pos(false),          pos(B)), hold(B).

