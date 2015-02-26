// Copyright 2015 Eric Butler, Adam M. Smith, Erik Andersen.

// top-level application code. includes "entry points" for index.html and viewer.html
var App = (function() { 'use strict';
    var mdl = {};

    function classOfListItem(data, idx) {
        return idx % 2 == 0 ? "li_even" : "li_odd";
    }

    /// given a model of the progression engine (via get_model()),
    /// update the UI that visualizes the model.
    function update_progression_visualization(model) {
        function htmlOfFeature(mastery, feature) {
            var feature = model.features[feature];
            var cval_class = mastery == 0 ? 'cval0' : 'cval';
            return '<span class="cweight">' + (feature.weight * 1.0) + '</span><span class="cname">' + feature.feature + '</span><span class="' + cval_class + '">' + mastery + '</span>';
        }

        $('#target-cost').html(model.target_cost);
        $('#current-cost').html(model.current_cost);

        var ll = d3.select('#curr_list');
        ll.selectAll('*').remove();
        ll.selectAll('li')
            .data(model.current_node.label).enter().append('li')
            .html(function(d){return htmlOfFeature(model.completed[d],d);})
            .attr('class', classOfListItem)
            ;

        var mastery = _.map(model.completed, htmlOfFeature);
        var ml = d3.select('#mastery_list');
        ml.selectAll('*').remove();
        ml.selectAll('li')
            .data(mastery).enter().append('li')
            .html(function(d){return d;})
            .attr('class', classOfListItem)
            ;
    }

    /// the game's "main loop."
    function run_game(puzzle_package) {
        var progression = Progression.create(puzzle_package);
        var board = Board.create('#game-svg', 'play_mode');
        var level;

        function on_piece_update(locations) {
            // update lasers, calculate win condition
            var lasers = Game.calculate_laser_flow(level.data.pieces, locations);
            var is_win = Game.check_is_win(level.data.pieces, locations, lasers);
            board.draw_lasers(lasers);

            // turn on advance button if win condition is set
            $('#puz-unsolved').toggle(!is_win);
            $('#puz-solved').toggle(is_win);
        }

        function update_level(did_win) {
            level = progression.next_level(did_win);
            board.set_level(level, on_piece_update);
            update_progression_visualization(progression.get_model());
        }

        // start first level
        update_level(undefined);

        $('#btn-advance').click(function() {
            update_level(true);
        });
        $('#btn-abort').click(function() {
            update_level(false);
        });
    }

    // entry point for player called by index.html once everything has loaded.
    mdl.start_game = function() {
        // randomize the credits
        var credits = _.shuffle(["Eric Butler", "Adam M. Smith", "Erik Andersen"]);
        d3.selectAll('.credits').data(credits).text(function(d){return d;});

        $.get('puzzles.json')
            .done(run_game)
            .fail(function() {
                alert("Could not find puzzles.json! See the README for how to create one.");
            });
    };

    // entry point for the puzzle viewer (viewer.html).
    mdl.start_viewer = function() {
        var board = Board.create('#game-svg', 'view_mode');
        var puzzles;
        var current_puzzle;

        function string_hash(s) {
            return s.split("").reduce(function(a,b){a=((a<<5)-a)+b.charCodeAt(0);return a&a},0);
        }

        function on_piece_update(locations) {
            // update lasers, calculate win condition
            var lasers = Game.calculate_laser_flow(current_puzzle.level.data.pieces, locations);
            board.draw_lasers(lasers);
        }

        function htmlOfFeature(feature) {
            return '<span class="cweight">' + (feature.weight * 1.0) + '</span><span class="cname">' + feature.feature + '</span>';
        }

        function setup(puzzle_str) {
            // puzzles are one per line (also drop any excess newlines)
            var puzzles = _.filter(puzzle_str.split("\n"), function(s) { return s.length > 0; });

            var color_scale = d3.scale.category20();

            // create a selection list for every puzzle in the downloaded file
            d3.select('#puzzle-list').selectAll('option')
                .data(puzzles).enter().append('option')
                .attr('value',function(d,i) { return i; })
                .each(function(d,i) {
                    // set color of element to a hash of the config
                    var elem = this;
                    setTimeout(function() {
                        var hash = string_hash(JSON.stringify(JSON.parse(d).extra.batch_config));
                        d3.select(elem).style('background', color_scale(hash));
                    },0);
                })
                .text(function(d,i) { return i;})
                ;

            $('#puzzle-list').change(function(s) {
                current_puzzle = JSON.parse(puzzles[this.value]);
                console.log(current_puzzle);
                board.set_level(current_puzzle.level, on_piece_update);

                var ll = d3.select('#curr_list');
                ll.selectAll('*').remove();
                ll.selectAll('li')
                    .data(current_puzzle.label).enter().append('li')
                    .html(htmlOfFeature)
                    .attr('class', classOfListItem)
                    ;
            });
        }

        $.get('puzzles.txt')
            .done(setup)
            .fail(function() {
                alert("Could not find puzzles.txt! See the README for how to create one.");
            });
    };

    return mdl;
}());
