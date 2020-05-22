#!/bin/sh

basename=`basename $0`

if [ -z "$*" ]; then
	echo "usage: ${basename} <dot> [ -o | -r | <file> | - ]"
	echo ""
	echo "options:"
	echo "  -o      open dot in window with keyboard focus"
	echo "  -r      read contents of dot"
	echo "  -c      clear contents of dot"
	echo "  <file>  append contents of regular file to dot"
	echo "  -       append standard input to dot"
	echo ""
	echo "examples:"
	echo "  $ cal -h | tot 1 -    # put a calendar in first dot"
	echo "  $ tot 2 MyApp.crash   # put a crash report in second dot"
	echo ""
	exit 1
fi

dot="$1"
if [ -z "$2" ]; then
	echo "error: no dot action specified"
	exit 1
else
	if [ "$2" = "-o" ]; then
		# open dot
		osascript -e "tell application \"Tot\" to open location \"tot://${dot}\""
		osascript -e "tell application \"Tot\" to activate"
	elif [ "$2" = "-r" ]; then
		# get contents of dot
		osascript -e "tell application \"Tot\" to open location \"tot://${dot}/content\""
	elif [ "$2" = "-c" ]; then
		# clear contents of dot
		osascript -e "tell application \"Tot\" to open location \"tot://${dot}/replace?text=\""
	else
		# append file or stdin to dot
		if [ "$2" = "-" ]; then
			FILE=`mktemp -t ${basename}` || exit 1
			cat /dev/stdin > $FILE
		else 	
			if [ -f "$2" ]; then
				FILE="$2"
			else
				echo "error: not a regular file"
				exit 1
			fi
		fi

		text=`cat $FILE | python2 -c 'import urllib; import sys; print urllib.quote(sys.stdin.read())'`
		osascript -e "tell application \"Tot\" to open location \"tot://${dot}/append?text=${text}\""
	fi
fi
