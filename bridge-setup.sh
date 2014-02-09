#!/usr/bin/zsh

myname=`basename $0`
TUSER=`whoami`

case "$#" in
0|1|2)
        echo "usage: $myname bridge_intf start_tapid end_tapid" 1>&2;
        exit 1
        ;;
*)      BRIDGE_INTF="$1"; START_TAPID="$2" ; END_TAPID="$3"
        shift;
        shift
        ;;
esac

echo " bridge intf: ${BRIDGE_INTF} - start: ${START_TAPID} - end: ${END_TAPID}"
echo "tunnel owner: ${TUSER}"

/sbin/ifconfig ${BRIDGE_INTF}
if [ "$?" = "0" ]; then
  echo "interface ${BRIDGE_INTF} exists -- adding tap interface(s) to ${BRIDGE_INTF}"
else
	echo "interface ${BRIDGE_INTF} missing -- creating ...";
  /usr/bin/sudo ovs-vsctl add-br ${BRIDGE_INTF};
fi

foreach i (`seq $START_TAPID $END_TAPID`)
  echo "-- creating interface tap${i}"
  /usr/bin/sudo tunctl -u ${TUSER} -t tap${i}            ;
  /usr/bin/sudo ifconfig tap${i} up                      ;
  echo "-- adding tap${i} to ${BRIDGE_INTF}"
  /usr/bin/sudo ovs-vsctl add-port ${BRIDGE_INTF} tap${i};
end

#-------------------------------------------------------------------------------
# functions
seq () {
  local lower upper output;
  lower=$1 upper=$2;

while [ $lower -le $upper ];
do
  output="$output $lower";
  lower=$[ $lower + 1 ];
done;

  echo $output
}
