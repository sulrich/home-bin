#!usr/bin/env python


import csv
import os, sys, getopt

user = os.getlogin()


def main(argv):
    if not argv:
        printUsage()
        sys.exit(2)
    else:
        mapfile = argv[0]

    print "map file: " + mapfile
    generateBridges(mapfile)


def printUsage():
    print """
    bridge-builder.py <path to mapfile>

    where the mapfile is a comma delimited list of tap/bridge/vlan mappings
    """


def generateBridges(mapfile):
    with open(mapfile, 'rb') as csvfile:
        intflist = csv.reader(csvfile, delimiter=',', quotechar='"')
        for row in intflist:
            print "/usr/bin/sudo tunctl -u %s -t tap%s" % (user, row[1])
            print "/usr/bin/sudo ifconfig tap%s up" % (row[1])
            print "/usr/bin/sudo tunctl -u %s -t tap%s" % (user, row[2])
            print "/usr/bin/sudo ifconfig tap%s up" % (row[2])
            print "/usr/bin/sudo ovs-vsctl add-br %s" % (row[0])
            print "/usr/bin/sudo ovs-vsctl add-port %s tap%s" % (row[0], row[1])
            print "/usr/bin/sudo ovs-vsctl add-port %s tap%s" % (row[0], row[2])


if __name__ == "__main__":
    main(sys.argv[1:])
