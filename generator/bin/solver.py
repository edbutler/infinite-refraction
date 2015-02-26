# Python 2.7+

from __future__ import absolute_import, print_function, unicode_literals

import os
import sys
import json
import inspect
from subprocess import Popen, PIPE

_localdir = os.path.abspath(os.path.dirname(inspect.getfile(inspect.currentframe())))
_aspdir = os.path.join(_localdir, '..')

def run_subproc(cmd, do_show_stderr=False):
    cwd = os.path.join(_aspdir)
    stderr = None if do_show_stderr else PIPE
    proc = Popen(cmd, cwd=cwd, shell=False, stdout=PIPE, stderr=stderr)
    stdout, stderr = proc.communicate()
    return stdout

def run_subproc_with_stdin(cmd, stdin, do_show_stderr):
    cwd = os.path.join(_aspdir)
    stderr = None if do_show_stderr else PIPE
    proc = Popen(cmd, cwd=cwd, shell=False, stdout=PIPE, stdin=PIPE, stderr=stderr)
    stdout, stderr = proc.communicate(stdin)
    return stdout

def extract_all_models_from_outf2(stdout):
    x = json.loads(stdout)
    return [w["Value"] for w in x["Call"][0]["Witnesses"]]

