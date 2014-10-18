#!/bin/bash


/usr/bin/rsync -avHS --delete-after ${HOME}/mail                 sulrich@bert.local.:/home/sulrich/archives/juniper/mail
/usr/bin/rsync -avHS --delete-after ${HOME}/Desktop              sulrich@bert.local.:/home/sulrich/archives/juniper/desktop
/usr/bin/rsync -avHS --delete-after ${HOME}/Documents/work       sulrich@bert.local.:/home/sulrich/archives/juniper/documents
