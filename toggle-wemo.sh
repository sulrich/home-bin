#!/bin/bash

export PATH="${HOME}/.pyenv/bin:$PATH"
eval "$(pyenv init --path)"
# eval "$(pyenv init -)"

# toggle the power on the wemo bridge.  
WEMO_PORT=4

${HOME}/bin/botpower.py -a off -o ${WEMO_PORT}
sleep 10
${HOME}/bin/botpower.py -a on  -o ${WEMO_PORT}
