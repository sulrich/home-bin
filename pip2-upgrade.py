#!/usr/bin/env python2

import pip
from subprocess import call

for dist in pip.get_installed_distributions():
    call("pip install --upgrade --user " + dist.project_name, shell=True)
