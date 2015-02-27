#!/usr/bin/python
# Python 2.7+

# Copyright 2015 Eric Butler, Adam M. Smith, Erik Andersen.

from __future__ import absolute_import, print_function, unicode_literals

import sys, os, errno
import json
import argparse
from collections import defaultdict
from multiprocessing import Pool

localdir = os.path.abspath(os.path.dirname(__file__))
sys.path.append(os.path.join(localdir,'bin'))
import solver
import refraction

def mkdir_p(path):
    try:
        os.makedirs(path)
    except OSError as exc:
        if not (exc.errno == errno.EEXIST and os.path.isdir(path)):
            raise

# do_<foo> is the implementation for subcommand <foo>.

def _do_make_labels(line):
    '''The work function to compute a labeling for a single puzzle.'''
    data = json.loads(line)
    out = solver.run_subproc_with_stdin("./bin/label.sh", refraction.rules_from_level(data["level"]), do_show_stderr=args.verbose)
    # extract the json from the clingo output using super-robust "parsing", this is the level format to be dumped
    output = out.split('OUTPUT;')[1].split("\n")[0]
    return output

def do_label(args):
    # labeling sends levels, one at a time, to bin/label.sh,
    # then just cats the entire thing back together.
    # It uses a thread pool to parallelize.

    if args.numproc > 1:
        lines = [line for line in sys.stdin if len(line) > 1]
        pool = Pool(processes=args.numproc)
        result = pool.map(_do_make_labels, lines)
        map(print, result)
    else:
        for line in sys.stdin:
            print(_do_make_labels(line))

def do_configure(args):
    # just run bin/configure.sh with no arguments!
    output = solver.run_subproc("./bin/configure.sh", do_show_stderr=args.verbose)
    config_dir = os.path.join(localdir, 'configs')
    mkdir_p(config_dir)

    models = solver.extract_all_models_from_outf2(output)
    for idx, witness in enumerate(models):
        with open(os.path.join(config_dir, 'batch.%d.lp' % idx), 'w') as f:
            f.write("\n".join([r + "." for r in witness]))

    print('Wrote %d config files to ./configs/' % len(models), file=sys.stderr)

def do_generate(args):
    batch_file = 'configs/batch.%d.lp' % args.batch_id
    # first generate unlabeled puzzles
    output = solver.run_subproc(["./bin/generate.sh", batch_file, str(args.num)], do_show_stderr=args.verbose)
    models = solver.extract_all_models_from_outf2(output)

    # then label each puzzle and print to stdout
    for m in models:
        rules = "\n".join([r + "." for r in m])
        # this will print a bunch of warnings because import_level.lp won't do anything but that's okay
        out = solver.run_subproc_with_stdin("./bin/label.sh", rules, do_show_stderr=args.verbose)
        output = out.split('OUTPUT;')[1].split("\n")[0]
        print(output)

def do_sample(args):
    # just run bin/sample.sh with no arguments!
    output = solver.run_subproc("./bin/sample.sh", do_show_stderr=args.verbose)
    print(output)

def do_package(args):
    # packaging involves the following things:
    # - grouping levels with same features together
    # - creating a list of all features and their weights.
    # - creating a mapping from puzzles to items in the feature list.
    #
    # (it used to make a graph which is why they're called "nodes"
    #  but actually it's just bag of puzzles).

    mmap = defaultdict(list)

    # read puzzles from stdin, group by features
    for line in sys.stdin:
        if len(line) == 0:
            continue
        data = json.loads(line)
        mmap[frozenset([(l["feature"], l["weight"]) for l in data["label"]])].append(json.dumps(data["level"]))

    # the set of all feature values
    labelset = mmap.keys()

    # give every feature an identifier and put feature objects in format expected by game

    features = set()
    for l in labelset:
        features |= l

    def _feature(idx,g):
        return {
            "id": idx,
            "feature": g[0],
            "weight": g[1],
        }
    features = [_feature(i,g) for i, g in enumerate(features)]
    feature_to_id = dict([(g["feature"], g["id"]) for g in features])

    # now construct the list of nodes, indexed by feature id

    nodes = []

    # first fill in the data for each node
    for i, n in enumerate(labelset):
        nodes.append({"label":list([feature_to_id[l[0]] for l in  n]), "levels":mmap[n]})

    output = {"nodes":nodes, "features":features}
    print(json.dumps(output, sort_keys=True))

def do_print_stats(args):
    package = json.load(sys.stdin)
    print("Num features:", len(package["features"]))
    print("Num nodes:    ", len(package["nodes"]))
    print("Num levels:   ", len([lvl for node in package["nodes"] for lvl in node["levels"]]))

def do_extract(args):
    package = json.load(sys.stdin)

    def _get_level(lid):
        sp = lid.split('-')
        return ('"%s":' % lid) + package["nodes"][int(sp[0])]["levels"][int(sp[1])]

    levels = [_get_level(lid) for lid in args.levelid]
    print("{")
    print(",\n".join(levels) + "\n}")

def do_aspify(args):
    lines = [line for line in sys.stdin if len(line) > 1]
    line = json.loads(lines[args.index])
    print(refraction.rules_from_level(line['level']))

def do_find(args):
    package = json.load(sys.stdin)
    feature_table = dict([(p["id"], p["feature"]) for p in package["features"]])

    if args.number is not None:
        nodes = [n["label"] for n in package["nodes"] if len(n["label"]) == args.number]
        for n in nodes:
            print([feature_table[x] for x in n])

if __name__ == "__main__":

    # BASE PARSERS
    ######################################################################

    parser = argparse.ArgumentParser(description='Runner to generate/label puzzles for Refraction.')
    subprs = parser.add_subparsers(title="commands")

    # common args
    common_parser = argparse.ArgumentParser(add_help=False)
    common_parser.add_argument('-v', '--verbose', dest='verbose', action='store_true', default=False, help="Verbose mode. Show stderr for ASP solver on stderr.")

    configure_parser = subprs.add_parser('configure', help='Generate configuration files for the puzzle generator, which are needed to launch the batch of generation processes.', parents=[common_parser])
    configure_parser.set_defaults(func=do_configure)

    generate_parser = subprs.add_parser('generate', help='Generate and label puzzles based on a single configuration file. Prints puzzles on stdout.', parents=[common_parser])
    generate_parser.set_defaults(func=do_generate)
    generate_parser.add_argument('--num', '-n', dest='num', default=5, type=int, help="How many puzzles to generate for this configuration. Defaults to 5.")
    generate_parser.add_argument('batch_id', type=int, help="The batch id to generate (The <n> in configs/batch.<n>.lp).")

    label_parser = subprs.add_parser('relabel', help='Recompute labels on an existing puzzle set (*.jsons) given over stdin, dumps new puzzle set to stdout.', parents=[common_parser])
    label_parser.set_defaults(func=do_label)
    label_parser.add_argument('-p', dest="numproc", default=1, type=int, help="The number of threads on which to label")

    package_parser = subprs.add_parser('package', help='Package a labeled level set for inclusion in the game. Expects puzzle set stream over stdin, outputs package (JSON) to stdout.')
    package_parser.set_defaults(func=do_package)

    sample_parser = subprs.add_parser('sample', help='Generate a single refractoin level with the default config, dump puzzle JSON to stdout. Will also drop last_level.json and last_level.lp in this directory, which contain the level data in two different forms (for testing purposes).', parents=[common_parser])
    sample_parser.set_defaults(func=do_sample)

    stats_parser = subprs.add_parser('stats', help='Prints stats about an output file sent over stdin.')
    stats_parser.set_defaults(func=do_print_stats)

    extract_parser = subprs.add_parser('extract', help='Extract the json for a particular set of levels into a standard level file (for easy testing).')
    extract_parser.set_defaults(func=do_extract)
    extract_parser.add_argument('levelid', nargs='*', help="Level ids to use, in the <node idx>-<level idx> format.")

    aspify_parser = subprs.add_parser('aspify', help='Aspify the json for a particular level from a *.jsons file (for testing labeling).')
    aspify_parser.set_defaults(func=do_aspify)
    aspify_parser.add_argument('index', type=int, help="The index in the jsons file of the level")

    find_parser = subprs.add_parser('find', help='Searches for nodes in a package with certain properties. Expects JSON package on stdin.')
    find_parser.set_defaults(func=do_find)
    find_parser.add_argument('-n', dest='number', type=int, default=None, help='find a node that contains this many features')

    args = parser.parse_args()
    args.func(args)

