#!/usr/bin/env python

import sys
import string
import mailbox
import email.utils
import operator
from collections import defaultdict
"""

given a maildir which contains a month's worth of email parse out the key
elements from the headers.

 - only pay attention to messages sent between cisco/google
 - senders (uniq)
 - total message count (per domain sender)
 - other useful stats

"""

mailer = "1e100"                              # only pay attn to joint messages

# only output the top N senders to the joint list set this to zero for all of
# the senders
topn = 10


def main(argv):
    if not argv:
        print "mail-stats.py <path to maildir>"
        sys.exit(2)
    else:
        parseMaildir(argv[0])


def parseMaildir(maildir):
    senders = defaultdict(int)                    # makes counting easy
    mesg_count = 0
    sender_fmt = 0                 # track the length of the senders for output

    mbox = mailbox.Maildir(maildir)
    for message in mbox:
        to = ''
        """
        for some reason my archives have emails without 'to' headers in
        there. this masks over these malformed messages
        """
        if 'to' in message:
            to = message['to']

        cc = ''                # cc header isn't always there
        if 'cc' in message:
            cc = message['cc']

        # only pay attention to messages sent directly to specified mailer
        if (mailer in to) or (mailer in cc):
            mesg_count += 1
            from_name, from_addr = email.utils.parseaddr(message['from'])
            if len(from_addr) > sender_fmt:
                sender_fmt = len(from_addr)
            senders[from_addr] += 1

    print " message count: %s" % mesg_count
    print "unique senders: %s" % len(senders.items())

    sorted_senders = sorted(senders.iteritems(), key=operator.itemgetter(1),
                            reverse=True)
    n = 0
    print "top %s sender(s)" % topn
    print "----------------"
    for sender in sorted_senders:
        if (n < topn) or (topn == 0):
            # print "%s - %s" % (sender[0], sender[1])
            print string.rjust(sender[0], sender_fmt),
            string.rjust(repr(sender[1]), 4)
            n += 1
        else:
            break

    print "\n\n"

if __name__ == '__main__':
    main(sys.argv[1:])
