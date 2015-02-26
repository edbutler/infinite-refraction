
See ../README.md for detailed instructions on running the generator.
This readme mostly covers technical details and a description of each file.

Requirements
-----------------------------------------------------------------------------
- a POSIX shell
- python 2.7
- clingo 3.3 (NOT 4)
- clasp 3.1 with thread support (or any disjuctive version)

Scripts will use the environment vars CLINGO3 and CLASP for clingo and clasp,
respectively. By default they are 'clingo' and 'clasp'.


How to Do Stuff
-----------------------------------------------------------------------------
Everything can be run using bin/runner.py.
None of the other scripts need to be run by hand.

Some quick terminology:
- Puzzle set/puzzle jsons:
    Text file with one puzzle in JSON format per line.
    This is the output of `generate`, expected input of `label` and others.
    It may or may not contain labels for the levels. `label` will add/overwrite
    the labels on a puzzle set and output a new puzzle set.
    `package` expects a labeled puzzle set.
- Puzzle package:
    A set of puzzles in a graph data structre.
    This is the format needed by the actual game.
    The output format of `package`, expected input of a few test commands.

Some pre-built puzzle sets are included in ../puzzles/.
Run `./runner.py -h` to see descriptions of other commands.
`./runner.py package` is required to get the resulting level pack into the game.
Everything else is for testing.


What Are All These Files Used For
-----------------------------------------------------------------------------

bin/
    runner.py       Script used to run all generation/labeling processes.
                    Use this script to do things.
    refraction.py   Converts game puzzle format (JSON) to ASP rules to be consumed by import_level.lp.
    solver.py       Some helper functions for running subprocs and parsing clingo output.
    sample.sh       Generates a single (unlabeled) puzzle using the disjunctive solver.
                    You can run this to test if level generation is working.
    label.sh        Lables a level (given on stdin) with the graphlets it contains.
                    This should not be invoked manually. Use `runner.py relabel`.
                    Also called as part of `runner.py generate`.
    generate.sh     Generates a set of puzzles, given a config file and number to generate as args.
                    This should not be invoked manually. Use `runner.py generate`.
    configure.sh    Uses ASP to generate all the config files for batching generation.
                    This should not be invoked manually. Use `runner.py configure`


The rest are ASP files (*.lp):

External Libraries:
metasp/*.lp         ASP metaprogramming, detailed in "Complex Optimization in Answer Set Programming" by Gebser et al.

Common Code:
refraction/
    math.lp         Fraction arithmetic, e.g., splitting (equal partitioning), adding.
    rules.lp        Game rules and board evalation, e.g., laser propagation, win conditions, piece placement.
    levelfile.lp    Translates answer sets to datafile (JSON) that can be loaded into game.

Generation Code:
refraction/
    config.lp       Creates the configuration parameters that control puzzle generation, e.g., desired number of pieces.
    generate.lp     Choice rules and logic to generate puzzles where all solutions have the same structure.

Labeling/Analysis Code:
refraction/
    import_level.lp Rules for a "fixed" level for analysis (contrast to generate.lp).
                    Translates level(*) facts (calculated by runner.py) into facts used by rules.lp
    graphlets.lp    Calculates the features used to create the progression (like n-grams, on graphs).

