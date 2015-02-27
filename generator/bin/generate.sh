#!/bin/bash

# arguments:
# $1 config file name (e.g., configs/batch.1.lp)
# $2 number of models to generate 

# set default clingo/clasp commands if not already set
: ${CLINGO3:=clingo}
: ${CLASP:=clasp}

$CLINGO3 $1 refraction/config.lp refraction/math.lp -t | \
$CLINGO3 - refraction/rules.lp refraction/generate.lp --reify | \
$CLINGO3 - metasp/meta.lp metasp/metaD.lp -l | \
$CLASP $2 -t 8 --restart-on-model --configuration=jumpy --outf=2 \
    --seed=$RANDOM --time-limit=300 --sign-def=3

