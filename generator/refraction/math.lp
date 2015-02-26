% Copyright 2015 Eric Butler, Adam M. Smith, Erik Andersen.

#begin_lua
  function log(b,x)
    return Val.new(Val.NUM,math.log(tonumber(x))/math.log(tonumber(b)))
  end

  function pow(b,x)
    return Val.new(Val.NUM,math.pow(tonumber(b),tonumber(x)))
  end 

  function reduce(f)
    local f_num = Val.args(f)[1]
    local f_denom = Val.args(f)[2]
    local d = _igcd(f_num,f_denom)
    return Val.new(Val.FUNC,{f_num/d,f_denom/d})
  end

  function sum(a,b)
    local n1 = Val.args(a)[1]
    local d1 = Val.args(a)[2]
    local n2 = Val.args(b)[1]
    local d2 = Val.args(b)[2]

    n = n1*d2+n2*d1
    d = d1*d2
    g = _igcd(n,d)
    return Val.new(Val.FUNC,{n/g,d/g})
  end

  function messysum(...)
    local num = Val.args(arg[1])[1]
    local denom = Val.args(arg[1])[2]
    for i,v in ipairs(arg) do
      if i > 1 then
        local f_num = Val.args(v)[1]
        local f_denom = Val.args(v)[2]
        num, denom = num*f_denom + f_num*denom, denom*f_denom
      end
    end
    return Val.new(Val.FUNC,{num,denom})
  end

  function _igcd(a,b)
    while b ~= 0 do
      a, b = b, a % b
    end
    return a
  end
#end_lua.

#const max_denominator = 18.
#const max_factors = 4.
#const max_target_inputs = 1.
#const max_splitter_outputs = 3.

denominator(D) :-
  P2 = 0..@log(2,max_denominator),
  P3 = 0..@log(3,max_denominator),
  P5 = 0..1,
  P7 = 0..1,
  P2 + P3 + P5 + P7 <= max_factors,
  D = @pow(2,P2) * @pow(3,P3) * @pow(5,P5) * @pow(7,P7),
  D <= max_denominator.

general_fraction(@reduce((N,D))) :-
  N = 1..D,
  denominator(D).

split_factor(1;2;3).

splitter_table(K,(A*K,B),(A,B)) :-
  K > 1,
  K <= max_splitter_outputs,
  split_factor(K),
  A #mod K == 0,
  general_fraction((A*K,B)),
  general_fraction((A,B)).

splitter_table(K,(A,B),(A,B*K)) :-
  K > 1,
  K <= max_splitter_outputs,
  split_factor(K),
  A #mod K != 0,
  general_fraction((A,B)),
  general_fraction((A,B*K)).

combiner_table(F1,F2,F) :-
  2 <= max_combiner_inputs,
  denominator(B1;B2),
  F1 := (1..B1,B1),
  F2 := (1..B2,B2),
  general_fraction(F1;F2;F),
  F = @sum(F1,F2).

%combiner_table(F1,F2,F3,F) :-
%  3 <= max_combiner_inputs,
%  denominator(B1;B2;B3),
%  F1 := (1..B1,B1),
%  F2 := (1..B2,B2),
%  F3 := (1..B3,B3),
%  F = @sum(F1,F2,F3),
%  general_fraction(F).

splitter2(I,O) :- splitter_table(2,I,O).
splitter3(I,O) :- splitter_table(3,I,O).
combiner2(I1,I2,O) :- combiner_table(I1,I2,O).
%combiner3(I1,I2,I3,O) :- combiner_table(I1,I2,I3,O).

