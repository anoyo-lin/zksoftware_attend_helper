#!/bin/bash
LOCAL=/root/mipsel
function kill_qemu() {
CNT=`ps -ef|grep tap.s|grep -v grep|wc -l`
if [[ $CNT > 2 ]]; then
	PID=`ps -ef|grep qemu|grep -v grep|awk '{ print $2 }'`
	kill -9 $PID
	for PID in `ps -ef|grep tap.s|grep -v grep|awk '{ if(NR<"'$[$CNT-1]'") {print $2} }'`
	do
	kill -9 $PID
	done
else
	return 0
fi
kill_qemu
}

function stop_br0() {
kill_qemu
if [[ "`brctl show|awk '{if(NR==2){print $1}}'`" == "br0" ]]; then
	ifconfig br0 down
	brctl delbr br0
	service network restart
fi
}

function init_qemu() {
kill_qemu
if [[ `rpm -qa|grep tunctl` == "" ]]; then
	modinfo tun
	modprobe tun
	yum install bridge-utils
	yum install tunctl
fi
ifconfig eth0 down
brctl addbr br0
brctl addif br0 eth0
brctl stp br0 off
brctl sethello br0 1
ifconfig br0 0.0.0.0 promisc up
ifconfig eth0 0.0.0.0 promisc up
dhclient br0
tunctl -t tap0 -u root
brctl addif br0 tap0
ifconfig tap0 0.0.0.0 promisc up
cd $LOCAL
qemu-system-mipsel -M malta -kernel output/images/vmlinux -serial stdio -hda output/images/rootfs.ext2 -append "root=/dev/hda" -net nic -net tap,ifname=tap0,script=no,downscript=no
}

function start_qemu() {
	kill_qemu
	cd $LOCAL
	qemu-system-mipsel -M malta -kernel output/images/vmlinux -serial stdio -hda output/images/rootfs.ext2 -append "root=/dev/hda" -net nic -net tap,ifname=tap0,script=no,downscript=no
}

function Usage() {
	while [ $# != 0 ]
	do
		case $1 in 
			"init" )
				if [[ `brctl show|awk '{if(NR==2){print $1}}'` == br0 ]];then
					start_qemu
				else
					init_qemu
				fi
				exit
			;;
			"kill" )
				stop_br0
				exit
			;;
			* )
				echo "init,kill"
				exit
		esac
	done
	if [ $# == 0 ];then
		echo "init,kill"
	fi
}
Usage "$@"
