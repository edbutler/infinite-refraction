// Copyright 2015 Eric Butler, Adam M. Smith, Erik Andersen.

// drawing and input handling of the svg representing the game board
var Board = function() {
    'use strict';

    var svgutil = {
        translate: function(x, y) {
            return "translate(" + x + "," + y + ")";
        }
    };

    var mdl = {};

    /// hooray for the extensive javascript math library
    function clamp(x,min,max) {
        return Math.min(Math.max(x, min), max);
    }

    // don't call this directly, requires new
    function Vec2(x,y) {
        this.x = x;
        this.y = y;
    }
    Vec2.prototype.toString = function() { return this.x + "," + this.y; };
    Vec2.prototype.clone = function() { return new Vec2(this.x, this.y); };
    Vec2.prototype.equals = function(other) { return this.x === other.x && this.y === other.y; };

    /// shallow vector/point object to avoid passing x and y separately all the time
    function vec2(x, y) { return new Vec2(x,y); }

    /// renderer for a "grid", which is basically the game board or the piece library.
    /// svg_elem: d3 selection, cell_size: float, size: Vec2, offset: Vec2
    function new_grid(svg_elem, cell_size, size, offset) {
        var self = {};

        var width = size.x;
        var height = size.y;
        var cell_scale = d3.scale.linear().range([0,cell_size]);
        var x_scale = d3.scale.linear().range([offset.x,cell_size+offset.x]);
        var y_scale = d3.scale.linear().range([offset.y,cell_size+offset.y]);

        svg_elem.classed('grid', true);
        svg_elem.attr('transform', svgutil.translate(offset.x, offset.y));

        self.svg = function() { return svg_elem; };

        self.draw_title = function(title) {
            svg_elem.append('text')
                .classed('title', true)
                .attr('x', 0)
                .attr('y', 0)
                .attr('dy', '-.4em')
                .text(title)
                ;
        };

        // x index of cell index (as integer)
        self.xidx_of = function(cellidx) {
            return cellidx % width;
        };

        // y index of cell index (as integer)
        self.yidx_of = function(cellidx) {
            return Math.floor(cellidx / width);
        };

        self.idx_of = function(cellidx) {
            return vec2(self.xidx_of(cellidx), self.yidx_of(cellidx));
        };

        // x pixel offset for the cell at the given x index
        self.x = x_scale;
        self.y = y_scale;

        // returns the closest cell for a cell-sized object with upper-left corner at given pixel pos (as Vec2).
        // return null if the object is not really on the grid
        self.closest_cell = function(pos) {
            var cell_x = Math.floor(x_scale.invert(pos.x + cell_size/2));
            var cell_y = Math.floor(y_scale.invert(pos.y + cell_size/2));
            if (cell_x >= 0 && cell_x < width && cell_y >= 0 && cell_y <= height) {
                return vec2(cell_x, cell_y);
            } else {
                return null;
            }
        };

        self.draw_grid = function() {
            // vertical lines
            svg_elem.append('g').selectAll('line')
                .data(_.range(0, width + 1))
                .enter().append('line')
                .attr('x1', cell_scale)
                .attr('y1', 0)
                .attr('x2', cell_scale)
                .attr('y2', cell_scale(height))
                ;
            // horizontal lines
            svg_elem.append('g').selectAll('line')
                .data(_.range(0, height + 1))
                .enter().append('line')
                .attr('y1', cell_scale)
                .attr('x1', 0)
                .attr('y2', cell_scale)
                .attr('x2', cell_scale(width))
                ;
        };

        self.draw_labels = function() {
            // column labels
            svg_elem.append('g').selectAll('text')
                .data(_.range(0, width))
                .enter().append('text')
                .attr('x', cell_scale)
                .attr('y', 0)
                .attr('dy', '1em')
                .attr('dx', '0.2em')
                .text(function(d) { return ""+d; })
                ;

            // row labels
            svg_elem.append('g').selectAll('text')
                // skip zero, it's same spot as column label
                .data(_.range(1, height))
                .enter().append('text')
                .attr('y', cell_scale)
                .attr('x', 0)
                .attr('dy', '1em')
                .attr('dx', '0.2em')
                .text(function(d) { return ""+d; })
                ;
        };

        return self;
    }

    function new_piece(parent_svg, id, jdata, size) {
        var elem = parent_svg.append('g')
            .classed('piece', true);
        var x = 0, y = 0;

        var text;
        if (jdata.value) {
            text = jdata.value.num + "/" + jdata.value.den;
        }

        var is_draggable = jdata.mobility === 'movable';
        elem.classed('draggable', is_draggable);

        function make_text(text, clas, offset) {
            elem.append('text')
                .classed(clas, true)
                .attr('x', size * 0.5 + offset.x)
                .attr('y', size * 0.5 + offset.y)
                .attr('dy', '.5em')
                .text(text);
        }

        function dir2angle(dir) {
            switch (dir) {
            case 'e': return 0;
            case 's': return 90;
            case 'w': return 180;
            case 'n': return 270;
            }
        }

        // get the rotation (in degrees) for the given board direction (n,s,e,w) and the direction the symbol is facing without rotation
        function rotation_of(dir, base) {
            var ang = dir2angle(dir) - dir2angle(base);
            return ang < 0 ? ang + 360 : ang;
        }

        function make_use(id, rotation) {
            var hs = size*0.5;
            var use = elem.append('use')
                .attr('xlink:href', id);
            if (rotation) {
                use.attr('transform', 'translate('+hs+','+hs+') rotate(' + rotation + ') translate(-'+hs+',-'+hs+')');
            }
        }

        // HACK all the hard-coded directions (e.g., 'n') are the default orientations of the svg assets

        switch (jdata.type) {
        case 'source':
            make_use('#sym-source', rotation_of(jdata.output, 'n'));
            make_text(text, 'shadow', vec2(2,2));
            make_text(text, 'source', vec2(0,0));
            break;
        case 'target':
            // assume targets have 1 input. (the original game supported multi-input targets, but infinite doesn't use them)
            make_use('#sym-target', rotation_of(jdata.inputs[0], 'n'));
            make_text(text, 'shadow', vec2(2,2));
            make_text(text, 'target', vec2(0,0));
            break;
        case 'blocker':
            elem.append('use').attr('xlink:href', '#sym-blocker');
            break;
        case 'bender':
            make_use('#sym-output', rotation_of(jdata.output, 's'));
            make_use('#sym-bender-base', rotation_of(jdata.input, 'n'));
            break;
        case 'splitter':
            _.each(jdata.outputs, function(dir) {
                make_use('#sym-output', rotation_of(dir, 's'));
            });
            var numout = jdata.outputs.length;
            make_use('#sym-splitter'+numout+'-base', rotation_of(jdata.input, 'n'));
            break;
        case 'combiner':
            make_use('#sym-output', rotation_of(jdata.output, 's'));
            var numin = jdata.inputs.length;
            _.each(jdata.inputs, function(dir) {
                make_use('#sym-combiner'+numin+'-base', rotation_of(dir, 'n'));
            });
            break;
        }

        var self = {};

        self.set_pos = function(new_x, new_y) {
            x = new_x;
            y = new_y;
            elem.attr('transform', svgutil.translate(x, y));
        };

        self.id = function() { return id; };
        self.is_draggable = function() { return is_draggable; };
        self.x = function() { return x; };
        self.y = function() { return y; };
        self.size = function() { return size; };
        self.svg = function() { return elem; };

        return self;
    }

    var cell_size = 60;
    var board_size = 10;
    var library_width = 3;

    /// initialize the board.
    /// svg_element is svg on which to draw the board.
    /// mode is one of {'play_mode', 'view_mode'}, controls whether we're playing the game or just viewing puzzles/solutions.
    mdl.create = function(svg_element, mode) {
        var self = {};

        var svg = d3.select(svg_element);
        var is_play_mode = mode === 'play_mode';

        // make the grids and stuff

        var board = new_grid(svg.append('g'), cell_size, vec2(board_size, board_size), vec2(20,40));
        board.draw_title("Game Board - Place pieces here");
        board.draw_grid();
        board.draw_labels();

        var library;
        if (is_play_mode) {
            library = new_grid(svg.append('g'), cell_size, vec2(library_width, board_size), vec2(680,40));
            library.draw_title("Library");
            library.draw_grid();
        }

        // load all the external svgs as symbols

        /// because Chrome is special and likes to block external svgs in symbols for some reason I cannot determine,
        /// we instead ajax it and manually copy the contents into the svg. HOORAY.
        /// if chrome wasn't causing problems we'd just use <use hlink:href="media/...svg"/> instead of this nonsense.
        function import_svg_symbol(url, id) {
            // append defs and symbols immediately (before async) so it comes before any uses in the svg
            var defs = svg.append('defs');
            var symbol = svg.append('symbol')
                .attr('id',id)
                .attr('viewBox', '0 0 150 150')
                .attr('width', cell_size)
                .attr('height', cell_size)
                ;
            // hooray for no error checking. who needs that
            $.get(url, function(doc) {
                // assumes the svg to copy in a group element with id "layer1"
                var g = $('#layer1',doc)[0];
                // strip the id since they are all going to conflict
                g.removeAttribute('id');
                symbol[0][0].appendChild(g);

                _.each($('defs > *',doc).toArray(), function(e) {
                    defs[0][0].appendChild(e);
                });
            }, 'xml');
        }

        import_svg_symbol('media/output.svg', 'sym-output');
        import_svg_symbol('media/bender.svg', 'sym-bender-base');
        import_svg_symbol('media/splitter2.svg', 'sym-splitter2-base');
        import_svg_symbol('media/splitter3.svg', 'sym-splitter3-base');
        import_svg_symbol('media/combiner2.svg', 'sym-combiner2-base');
        import_svg_symbol('media/combiner3.svg', 'sym-combiner3-base');
        import_svg_symbol('media/blocker.svg', 'sym-blocker');
        import_svg_symbol('media/source.svg', 'sym-source');
        import_svg_symbol('media/target.svg', 'sym-target');

        // level state (basically just where the pieces are, as an array of {grid:Grid, cell:Vec2} objects)
        var piece_locations = null;
        // the function to invoke when the board state changes (will calculate laser flow, etc.)
        var piece_update_callback = null;
        // and also the svg groups that hold lasers and pieces and stuff
        var g_lasers = svg.append('g');
        var g_pieces = svg.append('g');

        function invoke_piece_location_callback() {
            // game doesn't care about what's in library, so filter those out
            // invoke callback with a just a list of locations for cells on the board, null for others
            var locs = _.map(piece_locations, function(obj) {
                return obj ? (obj.grid === board ? obj.cell : null) : null;
            });
            piece_update_callback(locs);
        }

        // functions that handle pieces that are being dragged
        function dragfns(piece) {
            var x, y, start_x, start_y, max_x, max_y;
            var is_dragging = false;
            var start_cell;

            function start_drag(d, i) {
                // only drag on left click
                is_dragging = piece.is_draggable() && d3.event.sourceEvent.button === 0;
                var elem = d3.select(this);

                start_cell = piece_locations[piece.id()];
                start_x = piece.x();
                start_y = piece.y();
                x = start_x;
                y = start_y;
                max_x = parseInt(svg.attr('width')) - piece.size();
                max_y = parseInt(svg.attr('height')) - piece.size();

                // move off borad while picked up, reflow lasers
                piece_locations[piece.id()] = null;
                invoke_piece_location_callback();
            }

            function drag_move(d, i) {
                if (!is_dragging) return;
                x += d3.event.dx;
                y += d3.event.dy;

                x = clamp(x, 0, max_x);
                y = clamp(y, 0, max_y);

                piece.set_pos(x, y);
            }

            function stop_drag(d, i) {
                // figure out the nearest grid cell and drop it there.
                // if there isn't any place to put it,
                // of if the cell is occupied, then put it back where it used to be

                var p = vec2(x,y);
                var grid = board;
                var new_cell = board.closest_cell(p);
                if (!new_cell) {
                    grid = library;
                    new_cell = library.closest_cell(vec2(x,y));
                }

                // only move if the new cell is non-null and nothing else occupies that cell
                if (new_cell && _.all(piece_locations, function(loc) { return loc === null || loc.grid !== grid || !loc.cell.equals(new_cell); })) {
                    piece.set_pos(grid.x(new_cell.x), grid.y(new_cell.y));
                    // on successful relocation, notify model that an item's cell has changed
                    piece_locations[piece.id()] = {grid:grid, cell:new_cell};
                } else {
                    piece.set_pos(start_x, start_y);
                    piece_locations[piece.id()] = start_cell;
                }

                invoke_piece_location_callback();
            }

            return d3.behavior.drag()
                .origin(null)
                .on("dragstart", start_drag)
                .on("drag", drag_move)
                .on("dragend", stop_drag)
                ;
        }

        self.set_level = function(level, on_piece_update_fn) {

            // clear the old state
            piece_locations = [];
            piece_update_callback = on_piece_update_fn;

            var lib_idx_counter = 0;

            // use the index in the array as the piece id
            function make_piece(jdata, id) {
                var p = new_piece(g_pieces, id, jdata, cell_size);
                var cell;
                // draggable pieces go in the library, everything else on the board.
                // unless we're in view mode, in which case everything on the board if it has a position.
                // this will leave distractors off the board, but oh well
                if (p.is_draggable() && is_play_mode) {
                    cell = library.idx_of(lib_idx_counter++);
                    p.set_pos(library.x(cell.x), library.y(cell.y));
                    p.svg().call(dragfns(p));
                    // everything in the library has a 'null' location
                    piece_locations.push({grid:library, cell:cell});
                } else if (jdata.pos) {
                    cell = board.idx_of(jdata.pos);
                    p.set_pos(board.x(cell.x), board.y(cell.y));
                    piece_locations.push({grid:board, cell:cell});
                } else {
                    piece_locations.push(null);
                }
                return p;
            }

            g_pieces.selectAll("*").remove();
            _.each(level.data.pieces, make_piece);

            // make the "piece updated" calback immediately for the initial piece locations
            invoke_piece_location_callback();
        };

        self.draw_lasers = function(lasers) {
            g_lasers.selectAll('line').data([]).exit().remove();

            g_lasers.selectAll('line')
                .data(lasers)
                .enter().append('line')
                .classed('laser', true)
                .attr('x1', function(d){return board.x(d.src.x) + cell_size/2;})
                .attr('y1', function(d){return board.y(d.src.y) + cell_size/2;})
                .attr('x2', function(d){return board.x(d.dst.x) + cell_size/2;})
                .attr('y2', function(d){return board.y(d.dst.y) + cell_size/2;})
                .attr('stroke-width', function(d) {
                    return Math.max(2, Math.min(2, d.val.num/d.val.den) * 12);
                })
                ;
        };

        return self;
    };

    return mdl;
}();

