% Copyright 2015 Eric Butler, Adam M. Smith, Erik Andersen.

#begin_lua

    function interpolate(s, tab)
        return (s:gsub('($%b{})', function(w) return tab[w:sub(3,-2)] or w end))
    end

    getmetatable("").__mod = interpolate

    template = [[OUTPUT;{"level":{"ltype": "normal", "data": {"gver": 1, "pieces": [${pieces}]}, "fver": 1}, "label": [${label}], "extra": {"lasers": [${lasers}], "batch_config":{${batch_config}}}}]]

    function collect_all(pred, arity)
        if arity == nil then
            arity = 1 
        end
        local t = {}
        Assignment.begin(pred, arity)
        while Assignment.next() do
            -- XXX HACK this only works with ground-only programs! there is some bug with isTrue(), some preds were being dropped from originals.json, level 16, like (_num_target,1)
            --if Assignment.isTrue() then
                t[tostring(Assignment.args())] = Assignment.args()
            --end
        end
        return t
    end

    function pos(x,y)
        return x + 10 * y
    end

    function dirset(dirs)
        return string.gsub(string.gsub(tostring(dirs), "%(", "["), "%)", "]")
    end

    function source(x,y,out,num,den)
        local t = [[{"type":"source", "pos":%s, "output":"%s", "value":{"num":%s, "den":%s}}]]
        return string.format(t, pos(x,y), out, num, den)
    end

    function target(x,y,inp,num,den)
        local t = [[{"type":"target", "pos":%s, "inputs":["%s"], "value":{"num":%s, "den":%s}}]]
        return string.format(t, pos(x,y), inp, num, den)
    end

    function blocker(x,y)
        local t = [[{"type":"blocker", "pos":%s}]]
        return string.format(t, pos(x,y))
    end

    function bender(id,x,y,inp,out)
        local t = [[{"type":"bender", "pos":%s, "input":"%s", "output":"%s", "mobility":"movable"}]]
        return string.format(t, pos(x,y), inp, out)
    end

    function splitter(id,x,y,inp,out)
        local t = [[{"type":"splitter", "pos":%s, "input":"%s", "outputs":%s, "mobility":"movable"}]]
        return string.format(t, pos(x,y), inp, dirset(out))
    end

    function combiner(id,x,y,inp,out)
        local t = [[{"type":"combiner", "pos":%s, "inputs":%s, "output":"%s", "mobility":"movable"}]]
        return string.format(t, pos(x,y), dirset(inp), out)
    end

    function unused_bender(id,inp,out)
        local t = [[{"type":"bender", "input":"%s", "output":"%s", "mobility":"movable"}]]
        return string.format(t, inp, out)
    end

    function unused_splitter(id,inp,out)
        local t = [[{"type":"splitter", "input":"%s", "outputs":%s, "mobility":"movable"}]]
        return string.format(t, inp, dirset(out))
    end

    piece_handlers = {
      [{"source", 5}] = source,
      [{"target", 5}] = target,
      [{"blocker", 2}] = blocker,
      [{"bender", 5}] = bender,
      [{"splitter", 5}] = splitter,
      [{"combiner", 5}] = combiner,
      [{"unused_bender", 3}] = unused_bender,
      [{"unused_splitter", 3}] = unused_splitter, 
    }

    function onModel()
        pieces = {}

        for pred,handler in pairs(piece_handlers) do
          for _,pce in pairs(collect_all(unpack(pred))) do
              table.insert(pieces, handler(unpack(pce)))
          end
        end

        lasers = {}

        for _,beam in pairs(collect_all("beam",4)) do 
            table.insert(lasers, string.format([[{"s":%s, "e":%s}]], pos(beam[1], beam[2]), pos(beam[3], beam[4])))
        end

        batch_config = {}
        for _,config in pairs(collect_all("batch_config",2)) do
          table.insert(batch_config, string.format([["%s":"%s"]], tostring(config[1]), tostring(config[2]))) 
        end

        batch_config = {}
        for _,config in pairs(collect_all("batch_config",2)) do
          table.insert(batch_config, string.format([["%s":"%s"]], tostring(config[1]), tostring(config[2]))) 
        end
        table.sort(batch_config)

        label = {}
        for _,graphlet in pairs(collect_all("graphlet",2)) do
          table.insert(label, string.format([[{"feature": "%s", "weight": %s}]], tostring(graphlet[1]), tostring(graphlet[2]))) 
        end

        fillers = {
            pieces = table.concat(pieces,","),
            lasers = table.concat(lasers,","),
            label = table.concat(label,","),
            batch_config = table.concat(batch_config,",")
        }

        body = template % fillers

        print(body)

    end

#end_lua.

dir_name((0,lt),"e").
dir_name((0,gt),"w").
dir_name((1,lt),"s").
dir_name((1,gt),"n").

% un-hide after projection
hold(X) :- _hold(X).

% un-reify
graphlet(N,W) :- hold(atom(graphlet(N,W))).
batch_config(K,S) :- hold(atom(batch_config(K,S))).
placed(P) :- hold(atom(placed(P))).
included(P) :- hold(atom(included(P))).
included(P) :- placed(P). % because pre-made levels obviously include every placed piece
at_bit(A,P,B) :- hold(atom(at_bit(A,P,B))).
width(W) :- hold(atom(width(W))).
type(P,T) :- hold(atom(type(P,T))).
port(P,D,S) :- hold(atom(port(P,D,S))).
grid_edge(P1,P2,D) :- hold(atom(grid_edge(P1,P2,D))).
source_power(P,(N,D)) :- hold(atom(source_power(P,(N,D)))).
target_power(P,(N,D)) :- hold(atom(target_power(P,(N,D)))).
emits(Z,P,F) :- hold(atom(emits(Z,P,F))).
absorbs(Z,P,F,D) :- hold(atom(absorbs(Z,P,F,D))).

piece(P) :- type(P,T).
axis(A) :- at_bit(A,P,B).
bit(B) :- at_bit(A,P,B).
at_ac(A,P,C) :- piece(P), axis(A), C = #sum [at_bit(A,P,B)=2**B:bit(B) ].
at_xy(P,X,Y) :- at_ac(0,P,X), at_ac(1,P,Y), placed(P).
edge(P1,P2) :- grid_edge(P1,P2,D).
beam(X1,Y1,X2,Y2) :- edge(P1,P2), at_xy(P1,X1,Y1), at_xy(P2,X2,Y2).
portn(P,D,S) :- port(P,X,S), dir_name(X,D).

source(X,Y,O,N,D) :-          included(P), at_xy(P,X,Y), type(P,source), portn(P,O,out), source_power(P,(N,D)).
target(X,Y,I,N,D) :-          included(P), at_xy(P,X,Y), type(P,target), portn(P,I,in), target_power(P,(N,D)).
blocker(X,Y) :-               included(P), at_xy(P,X,Y), type(P,blocker).

bender(P, X,Y,I,O) :-            included(P), at_xy(P,X,Y), type(P,bender), portn(P,I,in), portn(P,O,out).
splitter(P, X,Y,I,(O1,O2)) :-    included(P), at_xy(P,X,Y), type(P,splitter2), portn(P,I,in), portn(P,O1,out), portn(P,O2,out), O1<O2.
splitter(P, X,Y,I,(O1,O2,O3)) :- included(P), at_xy(P,X,Y), type(P,splitter3), portn(P,I,in), portn(P,O1,out), portn(P,O2,out), portn(P,O3,out), O1<O2, O2<O3.
combiner(P, X,Y,(I1,I2),O) :-    included(P), at_xy(P,X,Y), type(P,combiner2), portn(P,I1,in), portn(P,I2,in), portn(P,O,out), I1<I2.
combiner(P, X,Y,(I1,I2,I3),O) :- included(P), at_xy(P,X,Y), type(P,combiner3), portn(P,I1,in), portn(P,I2,in), portn(P,I3,in), portn(P,O,out), I1<I2, I2<I3.

unused_bender(P, I,O) :-            included(P), not placed(P), type(P,bender), portn(P,I,in), portn(P,O,out).
unused_splitter(P, I,(O1,O2)) :-    included(P), not placed(P), type(P,splitter2), portn(P,I,in), portn(P,O1,out), portn(P,O2,out), O1<O2.
unused_splitter(P, I,(O1,O2,O3)) :- included(P), not placed(P), type(P,splitter3), portn(P,I,in), portn(P,O1,out), portn(P,O2,out), portn(P,O3,out), O1<O2, O2<O3.

#hide.
