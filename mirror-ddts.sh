#!/bin/zsh

SORTLIST="/tmp/ddts-sort-$$"
MIRRORDIR="${HOME}/tmp/google-ddts"

grep -i csc $1 | sed 's/[^a-zA-Z0-9]//g' | sort | uniq > ${SORTLIST}

foreach i (`cat ${SORTLIST}`)
  echo "mirroring $i - ${MIRRORDIR}/$i.txt";
  ${HOME}/bin/cdets-unix/bin/dumpcr ${i} > ${MIRRORDIR}/$i.txt;
end




# cleanup
rm ${SORTLIST}
