#!/bin/zsh

#rsync --ignore-existing -avz ftp.rfc-editor.org::ids-text-only/  ~/Sites/internet-drafts
#rsync --ignore-existing -avz www1.ietf.org::internet-drafts/ ~/Sites/internet-drafts
#rsync -avz www1.ietf.org::internet-drafts/ ~/Sites/internet-drafts
rsync --ignore-existing -avz --delete ftp.rfc-editor.org::ids-text-only/  ~/mirrors/internet-drafts
rsync --ignore-existing -avz --delete ftp.rfc-editor.org::rfcs-text-only/ ~/mirrors/rfc
