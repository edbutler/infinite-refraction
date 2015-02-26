#!/bin/bash

# set default clingo/clasp commands if not already set
: ${CLINGO3:=clingo}
: ${CLASP:=clasp}

$CLINGO3 -l refraction/config.lp -c invent_config=1 | $CLASP 0 --outf=2
