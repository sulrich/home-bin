#!/bin/bash

# every morning there are repos that i want to make sure I'm aware of updates to.
# just update this list of repos with the remote contents
#
# NOTE - *do not* use this for repos that i'm doing development on myself.
# these should be kept fresh through the usual channels.

declare -a REPO_LIST=(
  "${HOME}/src/openconfig/public"
  "${HOME}/src/openconfig/goyang"
  "${HOME}/src/yang"
  "${HOME}/src/grpc"
  "${HOME}/src/grpc-go"
  "${HOME}/src/vim-galore"

  # vim bundles
  "${HOME}/Dropbox/src/vim/bundle/NrrwRgn"
  "${HOME}/Dropbox/src/vim/bundle/SyntaxRange"
  "${HOME}/Dropbox/src/vim/bundle/ack.vim"
  "${HOME}/Dropbox/src/vim/bundle/calendar.vim"
  "${HOME}/Dropbox/src/vim/bundle/ctrlp.vim"
  "${HOME}/Dropbox/src/vim/bundle/dash.vim"
  "${HOME}/Dropbox/src/vim/bundle/gist-vim"
  "${HOME}/Dropbox/src/vim/bundle/jedi-vim"
  "${HOME}/Dropbox/src/vim/bundle/nerdcommenter"
  "${HOME}/Dropbox/src/vim/bundle/nerdtree"
  "${HOME}/Dropbox/src/vim/bundle/pig.vim"
  "${HOME}/Dropbox/src/vim/bundle/python-mode"
  "${HOME}/Dropbox/src/vim/bundle/syntastic"
  "${HOME}/Dropbox/src/vim/bundle/tabular"
  "${HOME}/Dropbox/src/vim/bundle/tagbar"
  "${HOME}/Dropbox/src/vim/bundle/ultisnips"
  "${HOME}/Dropbox/src/vim/bundle/utl.vim"
  "${HOME}/Dropbox/src/vim/bundle/vim-airline"
  "${HOME}/Dropbox/src/vim/bundle/vim-airline-themes"
  "${HOME}/Dropbox/src/vim/bundle/vim-autoclose"
  "${HOME}/Dropbox/src/vim/bundle/vim-colors-solarized"
  "${HOME}/Dropbox/src/vim/bundle/vim-fugitive"
  "${HOME}/Dropbox/src/vim/bundle/vim-git"
  "${HOME}/Dropbox/src/vim/bundle/vim-go"
  "${HOME}/Dropbox/src/vim/bundle/vim-indent-guides"
  "${HOME}/Dropbox/src/vim/bundle/vim-javascript"
  "${HOME}/Dropbox/src/vim/bundle/vim-json"
  "${HOME}/Dropbox/src/vim/bundle/vim-markdown"
  "${HOME}/Dropbox/src/vim/bundle/vim-misc"
  "${HOME}/Dropbox/src/vim/bundle/vim-notes"
  "${HOME}/Dropbox/src/vim/bundle/vim-orgmode"
  "${HOME}/Dropbox/src/vim/bundle/vim-pathogen"
  "${HOME}/Dropbox/src/vim/bundle/vim-pencil"
  "${HOME}/Dropbox/src/vim/bundle/vim-repeat"
  "${HOME}/Dropbox/src/vim/bundle/vim-snippets"
  "${HOME}/Dropbox/src/vim/bundle/vim-speeddating"
  "${HOME}/Dropbox/src/vim/bundle/vim-surround"
  "${HOME}/Dropbox/src/vim/bundle/webapi-vim"
  "${HOME}/Dropbox/src/vim/bundle/yang.vim"
  )

for REPO in "${REPO_LIST[@]}"; do
  echo "updating repo: ${REPO}"
  echo "----------------------------------------------------------------------"
  cd "${REPO}"
  git pull
done
