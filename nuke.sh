#!/bin/bash

# for when you drop the mic

declare -a PERSONAL=(
  "${HOME}/.gnupg"                # personal GPG keys
  "${HOME}/.config"               # personal misc. config files
  "${HOME}/.ssh"                  # personal ssh config
  "${HOME}/.jupyter"              #
  "${HOME}/.dropbox"              #
  "${HOME}/.ipython"              #
  "${HOME}/.gist-vim"             #
  "${HOME}/.gitconfig"            # has github credentials too
  "${HOME}/.getmail"              #
  "${HOME}/.vagrant.d"            #
  "${HOME}/.keybase-installer"    #
  "${HOME}/.notes"                #
  "${HOME}/.splunk"               #
  "${HOME}/.gnupg"                #
  "${HOME}/.docker"               #
  "${HOME}/.cpanm"                #
  "${HOME}/.lesshst"              #
  "${HOME}/.links"                #
  "${HOME}/.local"                #
  "${HOME}/.mairixdb"             #
  "${HOME}/.mairixrc"             #

  "${HOME}/.Rhistory"             #
  "${HOME}/.bash_history"         #
  "${HOME}/.zsh_history"          #


  # ~/Library stuff
  "${HOME}/Library/Messages"    # apple messages cache
  "${HOME}/Library/Calendars"   #
  "${HOME}/Library/Cookies"     #
  "${HOME}/Library/Application Support/1Password 4"   #
  "${HOME}/Library/Application Support/AddressBook"   #
  "${HOME}/Library/Application Support/Evernote"      #

  # containers
  "${HOME}/Library/Containers/com.dayoneapp.dayone"              #
  "${HOME}/Library/Containers/com.omnigroup.OmniFocus2"          #
  "${HOME}/Library/Containers/com.flexibits.fantastical2.mac*"   #


  # misc. directories, etc.
  "${HOME}/Documents/Wolfram Mathematica"
  "${HOME}/Documents/Colloquy Transcripts"
  "${HOME}/Documents/Microsoft User Data"
  "${HOME}/Documents/My Tableau Repository"
  "${HOME}/src/customer-configs"
  "${HOME}/tmp"

  "${HOME}/.home"              # my dotfiles!

) # end of PERSONAL directories list


for D in "${PERSONAL[@]}":
  do
    echo "removing: ${D}"
    # rm -rf "${D}"

done


echo "cleaning out misc dreck"
echo "cleaning out: ~/Downloads dir"
# rm -rf "${HOME}/Downloads/*"
echo "cleaning out: ~/Music dir"
# rm -rf "${HOME}/Music/*"




echo "clear safari history, etc."
echo "clear chome history, etc."
echo "clear chome user accounts"
echo "remember to unlink this computer from dropbox"
echo "remember to remove the itunes authorization for this host"
echo "remember to whack your 3rd party accounts (twitter, facebook, etc.)"
echo "remember to whack your ~/bin directory as well ..."
echo "remove jetdrive"
