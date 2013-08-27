#!/bin/zsh

ernie_home_remote="sulrich@ernie.botwerks.net:/home/sulrich"
ernie_home_local="/mnt/bigbird/home_dirs/sulrich/archives/ernie-backup" 
/usr/bin/rsync -av -e ssh --delete ${ernie_home_remote} ${ernie_home_local}

oscar_home_remote="sulrich@oscar.botwerks.net:/home/sulrich"
oscar_home_local="/mnt/bigbird/home_dirs/sulrich/archives/oscar-backup" 
/usr/bin/rsync -av -e ssh --delete ${oscar_home_remote} ${oscar_home_local}

combotwerks_remote="sulrich@oscar.botwerks.net:/usr/local/www/data/botwerks.com"
combotwerks_local="/mnt/bigbird/home_dirs/sulrich/archives/oscar-htdocs" 
/usr/bin/rsync -av -e ssh --delete ${combotwerks_remote} ${combotwerks_local}

orgbotwerks_remote="sulrich@oscar.botwerks.net:/usr/local/www/data/botwerks.org"
orgbotwerks_local="/mnt/bigbird/home_dirs/sulrich/archives/oscar-htdocs" 
/usr/bin/rsync -av -e ssh --delete ${orgbotwerks_remote} ${orgbotwerks_local}

psychowerks_remote="sulrich@oscar.botwerks.net:/usr/local/www/data/psychowerks.com"
psychowerks_local="/mnt/bigbird/home_dirs/sulrich/archives/oscar-htdocs" 
/usr/bin/rsync -av -e ssh --delete ${psychowerks_remote} ${psychowerks_local}

pcurator_remote="sulrich@oscar.botwerks.net:/usr/local/www/data/psychocurator.org"
pcurator_local="/mnt/bigbird/home_dirs/sulrich/archives/oscar-htdocs" 
/usr/bin/rsync -av -e ssh --delete ${pcurator_remote} ${pcurator_local}
