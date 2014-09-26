#!/bin/zsh

#IMAGE=$(basename "$2")
#IMG_BASE=${IMAGE%%.*}

case $1 in 
  (boot-iso*)
    echo "generating vmdk file $IMG_BASE.vmdk"
    qemu-img create -f vmdk $IMG_BASE.vmdk 2G
    echo "booting w/cdrom"  
    echo "telnet to localhost port 9101 in order to finish deployment process"
     qemu-system-x86_64 -nographic -m 3072 -cdrom $2 -boot d \
       -hda $2.vmdk                       \
       -serial telnet::9101,server,wait   \
       -serial telnet::9102,server,nowait \
       -serial telnet::9103,server,nowait \
       -net nic,model=e1000,vlan=1,macaddr=00:01:00:ff:00:00
;; 

  (boot-vmdk*)
   kvm -cpu kvm64 -daemonize -nographic -m 3072 -hda $2.qcow2 \
    -serial telnet::9101,server,nowait   \
    -net nic,model=virtio,vlan=1000,macaddr=00:01:00:ff:01:01 \
    -net tap,ifname=tap666,vlan=1000,script=no 
;; 

  (*)
   cat <<EOF
usage

EOF
;; 
esac


#kvm -cpu kvm64 -daemonize -nographic -m 2048 -hda ${HOME}/r2.img \
# -serial telnet::8102,server,nowait \
# -net nic,model=virtio,vlan=1000,macaddr=00:01:00:ff:01:02 \
# -net tap,ifname=tap1,vlan=1000,script=no \
 
