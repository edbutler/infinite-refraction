#!/bin/bash
clingo refraction/config.lp refraction/tablegen.lp -c default_config=1 -t | \
clingo - refraction/rules.lp refraction/generate.lp --reify | \
clingo - meta.lp metaD.lp -l | \
clasp 0 -t 8 --project --configuration=handy --outf=2 --seed=$RANDOM --time-limit=15 | \
tee ../last_batch.json
