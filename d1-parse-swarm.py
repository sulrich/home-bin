#!/usr/bin/env python
# -*- coding: utf-8 -*-

import argparse
import datetime
import re


def main(args):
    date = ""
    if args.date:
        date = datetime.datetime.strptime(args.date, "%Y-%m-%d")
        # we're only interested in the date info
        date = datetime.date(date.year, date.month, date.day)
    else:
        today = datetime.date.today()
        date = datetime.date(today.year, today.month, today.day)

    outbuff = "# %s - swarm entries\n\n"
    entry_re = re.compile("^(.*)\|(.*) - (\S+)", re.IGNORECASE)

    entries = ""
    with open(args.infile, 'wb') as swarmfile:
        # each entry is on a single file
        for l in swarmfile:
            entry = re.match(entry_re, l)
            if entry:
                edate = parseEntryDate(entry.group(1))
                if edate == date:
                    entries += "- " + entry.group(2)
                    entries += " (" + entry.group(3) + ")\n"

    outbuff += entries + "\n#swarm #social"
    if entries != "":
        print outbuff % date


def parseEntryDate(edate):
    d_re = re.match('^(.*) (\d{1,2}), (\d{4})', edate)
    pdate = ""
    if d_re:
        pdate = datetime.datetime.strptime(d_re.group(), "%B %d, %Y")
        # strip the time info
        pdate = datetime.date(pdate.year, pdate.month, pdate.day)
    return pdate


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('--infile', dest='infile', required=True,
                        help="file to parse for new checkins")
    parser.add_argument('--date', dest='date', required=False,
                        help="date to scan for checkins to import")

    args = parser.parse_args()
    main(args)
