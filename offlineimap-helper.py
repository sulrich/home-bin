#!/usr/bin/env python2

import os
import subprocess


def mailpasswd():
    # acct = os.path.basename(acct)
    path = "/Users/sulrich/.credentials/offlineimap-passwd.gpg"
    args = ["gpg2", "--quiet", "--batch", "-d", path]
    try:
        return subprocess.check_output(args).strip()
    except subprocess.CalledProcessError:
        return ""

    
