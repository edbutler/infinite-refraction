% Copyright 2015 Eric Butler, Adam M. Smith, Erik Andersen.

% this file specifies which pieces to use, should only be for generation.

% invent a batch configuration if "invent_config" constant is 1
#const invent_config=0.
batch_config_knob(Knob) :- batch_config_case(Knob,Setting).
1 { batch_config(K,S):batch_config_case(K,S) } 1 :- batch_config_knob(K), invent_config==1.

% use default config if "default_config" constant is 1
#const default_config=0.
batch_config(source_powers,one) :- default_config==1.
batch_config(blockers,2) :- default_config==1.
batch_config(sources,1) :- default_config==1.
batch_config(benders,1) :- default_config==1.
batch_config(splitter2s,1) :- default_config==1.
batch_config(splitter3s,1) :- default_config==1.
batch_config(many_targets,1) :- default_config==1.

%% describe possible config cases and their implications

% source_power impacts available source powers
batch_config_case(source_powers,one).
available_source_power((1,1)) :- batch_config(source_powers,one).

batch_config_case(source_powers,familiar_units).
familiar_unit((1,2);(1,3)).
available_source_power(F) :- familiar_unit(F), batch_config(source_powers,familiar_units).

%batch_config_case(source_powers,complex_units).
%available_source_power((N,D)) :- general_fraction((N,D)), N = 1, batch_config(source_powers,complex_units), not familiar_units((N,D)), D != 1.
%
%batch_config_case(source_powers,general).
%available_source_power((N,D)) :- general_fraction((N,D)), batch_config(source_powers,general), N != 1.

% pieces impacts distribution of available piece types for inclusion
batch_config_case(blockers,0;3;7;11).
batch_config_case(sources,1;2;4).
batch_config_case(benders,0;1;2;3;4;5).
batch_config_case(splitter2s,0;1;2;3;5;7;9).
batch_config_case(splitter3s,0;1;2;3;4).


% cross-facet constraints
:- batch_config(splitter2s,0), batch_config(splitter3s,0), not batch_config(source_powers,one).
:- batch_config(sources,S), num_target(N), N < S.

% extraction of numbers from confic
num_blocker(N) :- batch_config(blockers,N).
num_source(N) :- batch_config(sources,N).
num_bender(N) :- batch_config(benders,N).
num_splitter2(N) :- batch_config(splitter2s,N).
num_splitter3(N) :- batch_config(splitter3s,N).
batch_config_case(many_targets,0;1).
num_target(1+N2+N3) :- batch_config(many_targets,1), batch_config(splitter2s,N2), batch_config(splitter3s,N3). 
num_target(1) :-       batch_config(many_targets,0), batch_config(splitter2s,N2), batch_config(splitter3s,N3). 

% making piece ranges
source(1..N) :- num_source(N).
bender(1..N) :- num_bender(N).
splitter2(1..N) :- num_splitter2(N).
splitter3(1..N) :- num_splitter3(N).
blocker(1..N) :- num_blocker(N).
target(1..N) :- num_target(N).

% making actual pieces
type((src,X),source) :- source(X).
type((bnd,X),bender) :- bender(X).
type((sp2,X),splitter2) :- splitter2(X).
type((sp3,X),splitter3) :- splitter3(X).
type((trg,X),target) :- target(X).
type((blk,X),blocker) :- blocker(X).

piece(P) :- type(P,_).


