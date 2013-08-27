#!/usr//bin/zsh

myname=`basename $0`

TUSER=sulrich

case "$#" in
0|1|2)    
        echo "usage: $myname bridge_intf start_tapid end_tapid" 1>&2; 
        exit 1
        ;;
*)      bridge_int="$1"; start_tapid="$2" ; end_tapid="$3" 
        shift; 
        shift
        ;;
esac

echo "bridge: $bridge_int - start: $start_tapid - end: $end_tapid"
#exit


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

# sudo ovs-vsctl del-br br100
# sudo ovs-vsctl add-br br100




foreach i (`seq $start_tapid $end_tapid`)
  /usr/bin/sudo tunctl -u ${TUSER} -t tap${i}     ;
  /usr/bin/sudo ifconfig tap${i} up              ;
  /usr/bin/sudo ovs-vsctl add-port $bridge_int tap${i} ; 
end 




