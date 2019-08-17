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

  # arista repos - these have been deprecated for g* protocol work
  # "${HOME}/src/arista/gnmitest_common"
  # "${HOME}/src/arista/gnmitest_arista"
 
  # google repos
  "${HOME}/src/google/gnxi"
  "${HOME}/src/google/orismologer"

  # keep my vim fresh
  "${HOME}/.vim/pack/default/start/ale"
  "${HOME}/.vim/pack/default/start/black"
  "${HOME}/.vim/pack/default/start/dash.vim"
  "${HOME}/.vim/pack/default/start/fzf"
  "${HOME}/.vim/pack/default/start/ghost-text.vim"
  "${HOME}/.vim/pack/default/start/gist-vim"
  "${HOME}/.vim/pack/default/start/nerdcommenter"
  "${HOME}/.vim/pack/default/start/nerdtree"
  "${HOME}/.vim/pack/default/start/notational-fzf-vim"
  "${HOME}/.vim/pack/default/start/tabular"
  "${HOME}/.vim/pack/default/start/ultisnips"
  "${HOME}/.vim/pack/default/start/vim-airline"
  "${HOME}/.vim/pack/default/start/vim-airline-themes"
  "${HOME}/.vim/pack/default/start/vim-autoclose"
  "${HOME}/.vim/pack/default/start/vim-fugitive"
  "${HOME}/.vim/pack/default/start/vim-gitgutter"
  "${HOME}/.vim/pack/default/start/vim-go"
  "${HOME}/.vim/pack/default/start/vim-indent-guides"
  "${HOME}/.vim/pack/default/start/vim-isort"
  "${HOME}/.vim/pack/default/start/vim-javascript"
  "${HOME}/.vim/pack/default/start/vim-json"
  "${HOME}/.vim/pack/default/start/vim-markdown"
  "${HOME}/.vim/pack/default/start/vim-pencil"
  "${HOME}/.vim/pack/default/start/vim-polyglot"
  "${HOME}/.vim/pack/default/start/vim-repeat"
  "${HOME}/.vim/pack/default/start/vim-snippets"
  "${HOME}/.vim/pack/default/start/vim-surround"
  "${HOME}/.vim/pack/default/start/yang.vim"
)

for REPO in "${REPO_LIST[@]}"; do
  echo "updating repo: ${REPO}"
  echo "----------------------------------------------------------------------"
  cd "${REPO}" || exit
  git pull
  echo ""
done
