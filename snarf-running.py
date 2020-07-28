#!/usr/bin/env python3

import argparse
import re
import sys


def load_config(config_file):
    """ given a file path returns the configuration as a list for processing"""
    try:
        with open(config_file) as f:
            config = f.readlines()
            return config
    except IOError:
        print("error opening configuration file:", config_file)
        sys.exit()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        dest="showtech",
        help="show tech file to extract running configuration from",
    )

    args = parser.parse_args()

    config = []  # initialize the configuration
    config = load_config(args.showtech)

    show_tech_flag = False
    tech_str = "^-+ show running-config sanitized"
    tech_re = re.compile(tech_str)

    for line in config:
        skip = re.match(tech_re, line)
        config_end = re.match("^end", line)
        if not skip and not show_tech_flag:
            continue                      # skip to the next line
        elif skip and not show_tech_flag:  # starting the config section
            show_tech_flag = True
            continue              # we don't want to include this line in the outpu
        elif config_end and show_tech_flag:
            break

        print(line, end="")


if __name__ == '__main__':
    main()
