#!/bin/bash

# toggle the power on the wemo bridge.  
WEMO_PORT=4

${HOME}/bin/botpower.py -a off -o ${WEMO_PORT}
${HOME}/bin/botpower.py -a on  -o ${WEMO_PORT}
