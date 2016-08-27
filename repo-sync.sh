#!/bin/bash

# every morning there are repos that i want to make sure I'm aware of updates to.
# just update this list of repos with the remote contents
#
# NOTE - *do not* use this for repos that i'm doing development on myself.
# these should be kept fresh through the usual channels.

declare -a REPO_LIST=(
  "${HOME}/src/openconfig/public"
  "${HOME}/src/openconfig/goyang"
  "${HOME}/src/openconfig/reference"
  "${HOME}/src/openconfig/oc-pyang"
  "${HOME}/src/yang"
  "${HOME}/src/grpc"
  "${HOME}/src/grpc-go"
  "${HOME}/src/openconfig/juniper/openconfig"
  
  # vim stuff
  "${HOME}/src/vim-galore"
  "${HOME}/.vim/bundle/NrrwRgn"
  "${HOME}/.vim/bundle/SyntaxRange"
  "${HOME}/.vim/bundle/ack.vim"
  "${HOME}/.vim/bundle/calendar.vim"
  "${HOME}/.vim/bundle/ctrlp.vim"
  "${HOME}/.vim/bundle/dash.vim"
  "${HOME}/.vim/bundle/gist-vim"
  "${HOME}/.vim/bundle/jedi-vim"
  "${HOME}/.vim/bundle/nerdcommenter"
  "${HOME}/.vim/bundle/nerdtree"
  "${HOME}/.vim/bundle/pig.vim"
  "${HOME}/.vim/bundle/python-mode"
  "${HOME}/.vim/bundle/syntastic"
  "${HOME}/.vim/bundle/tabular"
  "${HOME}/.vim/bundle/tagbar"
  "${HOME}/.vim/bundle/ultisnips"
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
  "${HOME}/.vim/bundle/vim-orgmode"
  "${HOME}/.vim/bundle/vim-pathogen"
  "${HOME}/.vim/bundle/vim-pencil"
  "${HOME}/.vim/bundle/vim-repeat"
  "${HOME}/.vim/bundle/vim-snippets"
  "${HOME}/.vim/bundle/vim-speeddating"
  "${HOME}/.vim/bundle/vim-surround"
  "${HOME}/.vim/bundle/webapi-vim"
  "${HOME}/.vim/bundle/yang.vim"
  )

for REPO in "${REPO_LIST[@]}"; do
  echo "updating repo: ${REPO}"
  echo "----------------------------------------------------------------------"
  cd "${REPO}"
  git pull
done
