#!usr/bin/env python


import csv
import os, sys, getopt

user = os.getlogin()


def main(argv):
    mapfile = ''
    try:
        opts, args = getopt.getopt(argv,"hi:",["input_file="])
    except getopt.GetoptError:
        printUsage()
        sys.exit(2)

    for opt, arg in opts:
        if opt == '-h':
            printUsage()
            sys.exit()
        elif opt in ("-i", "--input_file"):
            mapfile = arg

    print "map file: " + mapfile
    generateBridges(mapfile)


def printUsage():
    print 'bridge-builder.py -i <input mapfile>'


def generateBridges(mapfile):
    with open(mapfile, 'rb') as csvfile:
        intflist = csv.reader(csvfile, delimiter=',', quotechar='"')
        for row in intflist:
            print "/usr/bin/sudo tunctl -u %s -t tap%s" % (user, row[1])
            print "/usr/bin/sudo ifconfig tap%s up" % (row[1])
            print "/usr/bin/sudo tunctl -u %s -t tap%s" % (user, row[2])
            print "/usr/bin/sudo ifconfig tap%s up" % (row[2])
            print "/usr/bin/sudo ovs-vsctl add-br br20%s" % (row[0])
            print "/usr/bin/sudo ovs-vsctl add-port br20%s tap%s" % (row[0], row[1])
            print "/usr/bin/sudo ovs-vsctl add-port br20%s tap%s" % (row[0], row[2])


if __name__ == "__main__":
    main(sys.argv[1:])
