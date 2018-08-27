#!/bin/bash
#
# this requires the use of the switchaudio-osx command line
# application.  this can be found at the following location:
#
# https://github.com/deweller/switchaudio-osx/
#
# also available via brew: brew install switchaudio-osx
#

# set audio device to be MM_1 speakers
/usr/local/bin/SwitchAudioSource -s "MM-1"

