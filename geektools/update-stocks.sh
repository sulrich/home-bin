#!/bin/bash

# path may require adjustment depending on where pyenv is installed
export PATH="${HOME}/.pyenv/bin:/usr/local/bin:$PATH"
eval "$(pyenv init -)"

STOCK_LIST="${HOME}/bin/geektools/stocks.yml"
"${HOME}/bin/geektools/stock-prices.py" "${STOCK_LIST}"
