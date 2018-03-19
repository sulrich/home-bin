#!/usr/bin/env python2.7

import pip
from subprocess import call

for dist in pip.get_installed_distributions():
    call("pip2 install --upgrade --user " + dist.project_name, shell=True)
