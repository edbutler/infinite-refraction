# Python 2.7+

from __future__ import absolute_import, print_function, unicode_literals
import json

def rules_from_level(level):
    rules = []
    counter = 0

    dir_name = {
        "e" : "(0,lt)",
        "n" : "(1,gt)",
        "w" : "(0,gt)",
        "s" : "(1,lt)",
    }

    def add_rule(rule):
        rules.append("level(%s)." % rule)

    def make_bit_rules(axis, pce, value):
        # assumes refraction grids are 10x10 (thus 4 bits enough for encoding)
        for idx in [0,1,2,3]:
            bit = (value >> idx) & 1

            if bit == 1:
                add_rule("at_bit(%s,%s,%s)" % (axis, pce, idx))
            else:
                add_rule("not_at_bit(%s,%s,%s)" % (axis, pce, idx))

    for piece in level["data"]["pieces"]:
        pid = counter
        counter += 1

        if piece["type"] == "splitter":
            add_rule("type(%s,splitter%s)" % (pid, len(piece["outputs"])))
        elif piece["type"] == "combiner":
            add_rule("type(%s,combiner%s)" % (pid, len(piece["inputs"])))
        else:
            add_rule("type(%s,%s)" % (pid, piece["type"]))

        if "pos" in piece:
            x = piece["pos"] % 10
            y = piece["pos"] / 10
            add_rule("at_xy(%s,%s,%s)" % (pid, x, y))
            make_bit_rules(0, pid, x)
            make_bit_rules(1, pid, y)

        if "output" in piece:
            add_rule("port(%s,%s,out)" % (pid, dir_name[piece["output"]]))
        elif "outputs" in piece:
            [add_rule("port(%s,%s,out)" % (pid, dir_name[d])) for d in piece["outputs"]]

        if "input" in piece:
            add_rule("port(%s,%s,in)" % (pid, dir_name[piece["input"]]))
        elif "inputs" in piece:
            [add_rule("port(%s,%s,in)" % (pid, dir_name[d])) for d in piece["inputs"]]

        if "value" in piece:
            val = piece["value"]
            add_rule("%s_power(%s,(%s,%s))" % (piece["type"], pid, val["num"], val["den"]))

    return "\n".join(rules)

