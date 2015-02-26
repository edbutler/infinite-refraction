// Copyright 2015 Eric Butler, Adam M. Smith, Erik Andersen.

// adaptive progression engine, responsible for choosing new puzzles
var Progression = function() {
    'use strict';
    var mdl = {};

    function sum_by(array, mapfn) {
        return _.reduce(array, function(acc, val, idx) {
            return acc + mapfn(val, idx);
        }, 0)
    }

    /// Create a new progression engine for the given puzzle data.
    mdl.create = function(level_data) {
        var self = {};

        var features = level_data.features;
        var nodes = level_data.nodes;
        // HACK hooray for magic numbers.
        // the version used in the CHI study had adaptive pacing, which changed this value
        // based on the rate of recent wins/losses. let's just keep it constant for simplicity.
        var target_cost = 1.5;

        // for each feature, how many puzzles with that feature have been completed
        // gets incremented on puzzle win, decremented on puzzle loss
        // this is a tremendously naive model.
        var completions = _.map(features, function(){ return 0; });

        // add an array to each node that marks whether the player has seen a certain puzzle before
        _.each(nodes, function(node) {
            node.has_seen_level = _.map(node.levels, function(){ return false; });
        });

        function base_cost_of_node(node) {
            return sum_by(node.label, function(feature_idx) {
                var weight = 0.1 / (1 + completions[feature_idx]);
                return features[feature_idx].weight * weight;
            });
        }

        function novelty_cost_of_node(node) {
            return sum_by(node.label, function(feature_idx) {
                var weight = completions[feature_idx] > 0 ? 0.0 : 1.0;
                return features[feature_idx].weight * weight;
            });
        }

        var last_level;

        self.next_level = function(did_win_previous) {
            // if there was a previous level, update model based on success/failure
            if (typeof did_win_previous === 'boolean') {
                if (!last_level) { throw "last level is null! can't update model!"; }
                // every feature in that level gets incremented/decrement based on win/loss.
                var delta = did_win_previous ? 1 : -1;
                _.each(nodes[last_level.node_idx].label, function(feature_idx) {
                    // don't let things drop below zero, that messes up the cost function
                    completions[feature_idx] = Math.max(0, completions[feature_idx] + delta);
                });
            }

            // then find the best node to use for the next level.
            // start by computing cost function over every node
            var costs = _.map(nodes, function(node, idx) {
                return {
                    node_idx: idx,
                    novelty: novelty_cost_of_node(node),
                    base: base_cost_of_node(node)
                };
            });

            // we preferably want to find a node with at least one new concept and one unused puzzle, so filter out everything else
            var possible_nodes = _.filter(costs, function(c) {
                // node has at least one unused concept if novelty score is positive
                return c.novelty > 0 && !_.all(nodes[c.node_idx].has_seen_level);
            });
            // if there are no such nodes, then instead relax requirement for unused concepts
            if (possible_nodes.length === 0) {
                possible_nodes = _.filter(costs, function(c) {
                    // node has at least one unused concept if novelty score is positive
                    return c.novelty > 0 && !_.all(nodes[c.node_idx].has_seen_level);
                });

                /// if that STILL failed, then also relax requirement for unseen puzzles
                // (i.e., just use the entire space of nodes)
                if (possible_nodes.length === 0) {
                    possible_nodes = costs;
                }
            }

            /// now select the node with the cost closest to the target cost.
            /// hooray for magic parameters
            var best_node = _.min(possible_nodes, function(c) {
                var cost = c.novelty + c.base;
                return Math.abs(cost - target_cost);
            });

            // grab the first unused level (or just the first if there isn't one)
            var next_unused_level_idx = Math.max(0, _.findIndex(nodes[best_node.node_idx].has_seen_level, function(b){return !b;}));

            last_level = {
                node_idx: best_node.node_idx,
                level_idx: next_unused_level_idx,
                cost: best_node.novelty + best_node.base,
            };

            // mark level as seen before returning it
            nodes[last_level.node_idx].has_seen_level[last_level.level_idx] = true;
            return JSON.parse(nodes[last_level.node_idx].levels[last_level.level_idx]);
        };

        /// returns an object representing the state of the model/progression,
        /// for use in visualizing the progression.
        self.get_model = function() {
            return {
                features: features,
                completed: completions,
                current_node: nodes[last_level.node_idx],
                current_cost: last_level.cost,
                target_cost: target_cost
            };
        }

        return self;
    };

    return mdl;
}();
