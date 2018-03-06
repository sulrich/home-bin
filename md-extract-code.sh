#!/bin/bash

# sed script to rip out the sections between _correctly_ paired source code
# blocks in a markdown file.

sed -n '/^```/,/^```/ p' < "${1}" | sed '/^```/ d'
