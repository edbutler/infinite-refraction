// Copyright 2015 Eric Butler, Adam M. Smith, Erik Andersen.

/// The game rules and simulation.
/// Mostly fraction math, the laser flow algorithm, and win condition checks.
var Game = (function() { 'use strict';
    var mdl = {};

    var board_size = 10;

    /// get the opposite direction of the given dir.
    function opposite(dir) {
        switch (dir) {
        case 'e': return 'w';
        case 's': return 'n';
        case 'w': return 'e';
        case 'n': return 's';
        }
    }

    /// shift a pos:Vec2 one cell in `dir` direction
    function offset(pos, dir) {
        switch (dir) {
        case 'n': pos.y--; break;
        case 'e': pos.x++; break;
        case 's': pos.y++; break;
        case 'w': pos.x--; break;
        }
    }

    /// a fraction (i.e. rational number) math module
    var frac = {};

    /// are two fractions equal?
    frac.equals = function(f1, f2) {
        return f1.num * f2.den === f1.den * f2.num;
    };

    /// divide a fraction by an integer n
    frac.split = function(frac, n) {
        // don't bother reducing since we don't display laser values anyway
        return {num:frac.num, den:frac.den*n};
    };

    /// add an array of fractions
    frac.add = function(fracs) {
        function addtwo(f1, f2) {
            // this is a very silly way to add rationals but good enough for this game,
            // since we only ever add fractions like at most 6 times per laser flow.
            // if it ever gets to be more, then just add code to reduce fractions after adding them.
            return {num:f1.num * f2.den + f2.num * f1.den, den:f1.den * f2.den};
        }

        return _.reduce(fracs, addtwo);
    };

    /// Calculate laser flow by propagating them from source pieces.
    /// Returns the set of lasers.
    mdl.calculate_laser_flow = function(pieces, locations) {
        // lookup table from cell to piece. it's an array of arrays
        var range = _.range(board_size);
        var piece_of_location = _.map(range, function() {
            return _.map(range, function() { return null; });
        });
        _.each(locations, function(loc, id) {
            if (loc) {
                piece_of_location[loc.x][loc.y] = id;
            }
        });

        var lasers = [];
        var new_lasers = [];

        // start a bunch of lasers at the sources
        _.each(pieces, function(p, id) {
            if (p.type === 'source') {
                new_lasers.push({src:locations[id],dir:p.output,val:p.value});
            }
        });

        // propagate lasers until no new ones remain (also bound by order of number of pieces in case there's a bug)
        var counter = 0;
        while (new_lasers.length > 0 && counter++ < pieces.length*3) {
            var copy = new_lasers;
            new_lasers = [];

            _.each(copy, function(laser){
                var pos = laser.src.clone();
                var hit_piece_id;
                laser.dst = pos;

                // move forward until it leaves the board or crashes into an object
                while (true) {
                    // move one cell forward
                    offset(pos, laser.dir);

                    if (pos.x < 0 || pos.x >= board_size || pos.y < 0 || pos.y >= board_size) {
                        // if we run off the board, we're done, with no new lasers
                        break;
                    } else if ((hit_piece_id = piece_of_location[pos.x][pos.y]) !== null) {
                        // if we hit a piece, case on the type and maybe create new lasers
                        var p = pieces[hit_piece_id];

                        switch (p.type) {
                        case 'bender':
                            // make sure laser actually hits the input
                            if (opposite(laser.dir) === p.input) {
                                // benders just route the laser out a new direction
                                new_lasers.push({src:pos,dir:p.output,val:laser.val});
                            }
                            break;
                        case 'splitter':
                            // make sure laser actually hits the input
                            if (opposite(laser.dir) === p.input) {
                                // splitters equally partition laser
                                var val = frac.split(laser.val, p.outputs.length);
                                _.each(p.outputs, function(out_dir) {
                                    new_lasers.push({src:pos,dir:out_dir,val:val});
                                });
                            }
                            break;
                        case 'combiner':
                            // combiners only fire when ALL inputs are satisfied (otherwise we can have infinite lasers!).
                            var indir = opposite(laser.dir);
                            // so first check if this laser goes into the combiner
                            if (_.contains(p.inputs, indir)) {
                                // then check if all other inputs are filled by existing lasers.
                                var other_in_lasers = _.map(_.without(p.inputs, indir), function(dir) {
                                    return _.find(lasers, function(l) { return l.dst.equals(pos) && opposite(l.dir) === dir});
                                });
                                if (_.all(other_in_lasers)) {
                                    var val = frac.add([laser.val].concat(_.map(other_in_lasers, function(l){return l.val;})));
                                    new_lasers.push({src:pos,dir:p.output,val:val});
                                }
                            }

                            break;
                        }

                        break;
                    }
                }

                lasers.push(laser);
            });
        }

        return lasers;
    }

    /// check the game's win condition (all targets have a laser entering them with the correct value)
    mdl.check_is_win = function(pieces, locations, lasers) {
        return _.all(pieces, function(p, id) {
            if (p.type === 'target') {
                var loc = locations[id];
                return _.any(lasers, function(laz) {
                    return laz.dst.equals(loc) &&
                        // assume only one input on targets (original game could have multiple but none of the infinite levels do)
                        opposite(laz.dir) === p.inputs[0] &&
                        frac.equals(laz.val, p.value);
                });
            } else {
                return true;
            }
        });
    };

    return mdl;
}());

