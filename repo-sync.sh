#!/bin/bash

# every morning there are repos that i want to make sure I'm aware of updates to.
# just update this list of repos with the remote contents
#
# NOTE - *do not* use this for repos that i'm doing development on myself.
# these should be kept fresh through the usual channels.

declare -a REPO_LIST=(
  # openconfig repos
  "${HOME}/src/openconfig/public" 
  "${HOME}/src/openconfig/gnmi"
  "${HOME}/src/openconfig/gnoi"
  "${HOME}/src/openconfig/goyang"
  "${HOME}/src/openconfig/oc-pyang"
  "${HOME}/src/openconfig/gnmitest"
  "${HOME}/src/openconfig/gribi"
  "${HOME}/src/openconfig/reference"
  "${HOME}/src/openconfig/ygot"
  "${HOME}/src/yang"

  # P4 repos
  "${HOME}/src/p4/tutorials"
  "${HOME}/src/p4/PI"
  "${HOME}/src/p4/p4-applications"
  "${HOME}/src/p4/p4-spec"

  # arista repos
  "${HOME}/src/arista/gnmitest_common"
  "${HOME}/src/arista/gnmitest_arista"

  # google repos
  "${HOME}/src/google/gnxi"
  "${HOME}/src/google/orismologer"
  
  # vim stuff
  "${HOME}/src/vim-galore"
  "${HOME}/.vim/bundle/SyntaxRange"
  "${HOME}/.vim/bundle/ack.vim"
  "${HOME}/.vim/bundle/ctrlp.vim"
  "${HOME}/.vim/bundle/dash.vim"
  "${HOME}/.vim/bundle/gist-vim"
  "${HOME}/.vim/bundle/nerdcommenter"
  "${HOME}/.vim/bundle/nerdtree"
  "${HOME}/.vim/bundle/pig.vim"
  "${HOME}/.vim/bundle/tabular"
  "${HOME}/.vim/bundle/utl.vim"
  "${HOME}/.vim/bundle/vim-airline"
  "${HOME}/.vim/bundle/vim-airline-themes"
  "${HOME}/.vim/bundle/vim-autoclose"
  "${HOME}/.vim/bundle/vim-colors-solarized"
  "${HOME}/.vim/bundle/vim-fugitive"
  "${HOME}/.vim/bundle/vim-git"
  "${HOME}/.vim/bundle/vim-go"
  "${HOME}/.vim/bundle/vim-indent-guides"
  "${HOME}/.vim/bundle/vim-javascript"
  "${HOME}/.vim/bundle/vim-json"
  "${HOME}/.vim/bundle/vim-markdown"
  "${HOME}/.vim/bundle/vim-misc"
  "${HOME}/.vim/bundle/vim-pathogen"
  "${HOME}/.vim/bundle/vim-repeat"
  "${HOME}/.vim/bundle/vim-surround"
  "${HOME}/.vim/bundle/yang.vim"
  # things which i've migrated to vim8's packaging tool
  "${HOME}/.vim/pack/git-plugins/start/ale"
  )

for REPO in "${REPO_LIST[@]}"; do
  echo "updating repo: ${REPO}"
  echo "----------------------------------------------------------------------"
  cd "${REPO}" || exit
  git pull
  echo ""
done
