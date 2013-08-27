#!/bin/zsh

# roll the current directory full of maildirs over to the archives.  this makes
# some assumptions as to the directory layout as specified in the $ARCH_DIR
# variable

LAST_MO_YEAR=`date -v -1m +%Y`
SRC_DIR=`basename ${PWD}`
ARCH_DIR="${HOME}/archives/cisco-mail/${LAST_MO_YEAR}/${SRC_DIR}"

# foreach m ( ${PWD}/* ) echo $m; end
echo "rolling over ${PWD} -> $ARCH_DIR"

foreach m (`basename ${PWD}/*`) ${HOME}/bin/split-maildirs.pl --keep_recent \
  --arch_dir=${ARCH_DIR}                                                    \
  --src_dir=${PWD}                                                          \
  $m; echo $m ; end
