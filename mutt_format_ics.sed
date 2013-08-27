#!/usr/bin/sed -nf
# A quick sed script to format a raw calendar entry in ICS format into a nicer
# looking plain text description.
# Copyright (c) 2008, Olivier Mehani <shtrom@ssji.net>
# All rights reserved.
#
# $Id: mutt_format_ics.sed 376 2008-06-12 07:47:45Z shtrom $
# Usage:
# This script can be used directly from the command line.
#	cat file.ics | mutt_format_ics.sed
#	mutt_format_ics.sed file.ics
#
#  The first goal of this script, though, is to be used from mutt. This is done
#  by adding a couple of lines of configuration:
#	- Somewhere in /etc/mime.types, ~/.mime.types,... add:
#		text/calendar                                   ics
#	  for the system to associate the right MIME type to ICS files.
#	- Somewhere in /etc/mailcap, ~/.mailcap,... add:
#		text/calendar;/PATH/TO/mutt_format_ics.sed %s; copiousoutput
#	  so that the system knows how to handle such files.
#	- Somewhere in /etc/Muttrc, ~/.muttrc,..., add:
#		auto_view text/calendar
#	  so that mutt uses mailcap information to display files with MIME type
#	  text/calendar.
#
#	Sample output:
#	===================
#	| iCalendar event |
#	===================
#	
#	|Starts:        2008-06-23 15:00
#	|Location:      Seminar room
#	|Ends:          2008-06-23 17:00
#	
#	Here is the description of the event
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
# 3. The name of the names of the contributors may be used to endorse or
#    promote products derived from this software without specific prior written
#    permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
# 

# catch the body of the calendar
/^BEGIN:VCALENDAR/,/^END:VCALENDAR/{
	# catch an event
	/^BEGIN:VEVENT/,/^END:VEVENT/{
		# nice formatting
		s/BEGIN:VEVENT/===================\n| iCalendar event |\n===================\n/p
		#s/^SUMMARY:\(.*\)$/Summary: \1\n/p
		s/^DTSTART.*:\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)T\([0-9]\{2\}\)\([0-9]\{2\}\).*/|Starts:\t\1-\2-\3 \4:\5/p
		s/^DTEND.*:\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)T\([0-9]\{2\}\)\([0-9]\{2\}\).*/|Ends:\t\t\1-\2-\3 \4:\5/p
		s/^LOCATION:/|Location:\t/p
		# FIXME: need a better handling
		s/^RRULE:FREQ=\([^;]\+\);UNTIL=\([^;T]\+\).*/|Repeats \1 until \2\t./p

		/^DESCRIPTION:/,/^[A-Z]\+:/{
			s/^DESCRIPTION:/\n/
			{
				# reformat the text properly

				:join
				$!N
				# remove extraneous iCal fields
				# FIXME: we never get out of the loop over the
				# VEVENT and lose all additional information
				# here
				s/\n[-A-Z]\+:.*//
				tjoin
				# actually join the lines
				s/\n //
				tjoin

				# replace \N by newlines, except the trailing
				# ones
				s/\(\\N\)\+$//
				s/\\N/\n/g
				# unescape other characters
				s/\\\(.\)/\1/g

				# try to wrap at 72 characters
				s/[^\n]\{72\} /&\n/g
				p
			}
		}
	}
}
