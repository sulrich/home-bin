#!/bin/bash

# toggle the power on the wemo bridge.  
WEMO_PORT=4

${HOME}/bin/botpower.py -a off -o ${WEMO_PORT}
echo "pausing 10 seconds ..."
sleep 10
echo "restarting wemo bridge"
${HOME}/bin/botpower.py -a on  -o ${WEMO_PORT}
