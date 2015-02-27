#!/bin/bash

# set default clingo command if not already set
: ${CLINGO3:=clingo}

$CLINGO3 - refraction/math.lp refraction/rules.lp refraction/import_level.lp refraction/graphlets.lp refraction/levelfile.lp --asp09 -q

