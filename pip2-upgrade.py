#!/usr/bin/env python2.7

from pip._internal.utils.misc import get_installed_distributions
# import pip
from subprocess import call

for dist in get_installed_distributions():
    call("pip2 install --upgrade --user " + dist.project_name, shell=True)
