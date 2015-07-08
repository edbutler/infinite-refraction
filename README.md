# Infinite Refraction

This is an open-source implementation of *Infinite Refraction*, a research project experimenting with automatically generated puzzles and progressions. It's based on the math puzzle game [*Refraction*](http://centerforgamescience.org/portfolio/refraction/). If you just want to check out *Infinite Refraction* now, you can [view the game online here](http://static.ericbutler.net/dist/infiniterefraction/).

## How do I use this

There are two parts of this project:
- A **puzzle generator** that uses logic programming to produce puzzles with hard constraints on solutions
- A version of the *Refraction* **game player** with a dynamic progression that uses these generated puzzles. This player has a lot of extra UI to illustrate how the progression is created.

File Structure:
- `generator/` contains the code used to generate puzzles.
- `game/` contains a HTML/JS game player and the progression generator.
- `puzzles/` contains pre-built sets of puzzles.

### Quick-start without running the generator

Getting the generator running is a bit complex, so the full set of generated puzzles is included in `puzzles/generated.txt`.
You'll need Python 2.7 installed. Run the following commands to get the pre-built puzzles into the game player:
```
cp puzzles/generated.txt game/puzzles.txt
python2.7 ./generator/runner.py package < game/puzzles.txt > game/puzzles.json
```
Browsers will probably block some of the files if loaded locally, so you'll probably need to launch a web server to play the game. There's a lot of options for this. For example, with Python 3:
```
cd game/
python3 -m http.server 7777
```
Then navigate to [http://localhost:7777](http://localhost:7777).

### Generating puzzles

Puzzles are generated using *Answer Set Programming* (ASP), specifically, the [Potassco Project](http://potassco.sourceforge.net/) tools *clingo* and *clasp*.

Requirements:
- A POSIX shell
- Python 2.7+
- clingo 3 (**NOT** 4, this relies on the 3-only feature `--reify`)
- clasp 3.1 with thread support (or any disjuctive version. You can actually use clingo 4 for this with `clingo --mode=clasp`)

Scripts will use the environment vars `CLINGO3` and `CLASP` for clingo and clasp,
respectively. By default they are `clingo` and `clasp`. Everything can be run using `bin/runner.py.` So, to generate a sample puzzle:
```
./generator/runner.py sample
```
This should dump some JSON that represents a *Refraction* puzzle to standard out if everything is working.

Generating the puzzles takes a very long time. The included `puzzles/generated.txt` contains over 9000 puzzles, generated on a computer cluster over an hour. So rather than generating them all at once, the system break the process down into multiple phases. First, generate a set of configuration files with
```
./generator/runner.py configure
```
which will populate `generator/configs/` with several thousand files that specify different potential puzzles. Then, a puzzle can be generated for a particular configuration *n* with
```
./generator/runner.py generate <n> >> game/puzzles.txt
```
This can be done in parallel for each configuration, the final result is a simple `cat` of all of the outputs. The resulting file should have one puzzle (as JSON) per line. These puzzles can be examined interactively with `game/viewer.html`, assuming `game/puzzles.txt` exists. Finally, the puzzles can be packaged up for the game player with
```
./generator/runner.py package < game/puzzles.txt > game/puzzles.json
```
and played by opening `game/index.html` using a web server.

## Copyright and license

All files, unless otherwise marked, are copyright 2015 Eric Butler, Adam M. Smith, and Erik Andersen.  
Licensed under the GNU General Public License, Version 3.

The files `meta.lp` and `metaD.lp` in `generator/metasp/` are part of the Potassco's [metasp](http://www.cs.uni-potsdam.de/wv/metasp/) and released under the GPLv3.
Copyright original authors.

The game viewer includes several JavaScript libraries in `game/lib/`.
Their respective licenses are included with the code.
Copyright their original authors.

## References

Related research:
- [Automatic Game Progression Design through Analysis of Solution Features](http://www.ericbutler.net/assets/papers/chi2015_progression.pdf)
- [Quantifying over Play: Constraining Undesirable Solutions in Puzzle Design](http://www.ericbutler.net/assets/papers/fdg2013_shortcuts.pdf)
- [A Case Study of Expressively Constrainable Level Design Automation Tools for a Puzzle Game](https://adamsmith.as/papers/fdg2012generation.pdf)

