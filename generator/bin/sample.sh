#!/bin/bash

# set default clingo/clasp commands if not already set
: ${CLINGO3:=clingo}
: ${CLASP:=clasp}

$CLINGO3 refraction/config.lp refraction/math.lp -c default_config=1 -t | \
$CLINGO3 - refraction/rules.lp refraction/generate.lp --reify | \
$CLINGO3 - metasp/meta.lp metasp/metaD.lp -l | \
$CLASP -t 4 --configuration=handy --outf=1 --sign-def=3 --seed=$RANDOM --eq=-1 | \
tee last_level.lp | \
grep -v ^% | \
grep -v ^ANSWER | \
$CLINGO3 - refraction/levelfile.lp -q --asp09 | tee last_level.json
