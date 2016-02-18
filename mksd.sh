#!/bin/bash

if [ $# -ne 1 ]; then
	echo -e "\033[1;31myour sdcard letter like /dev/sdx\e[m"
	exit 1
fi

SD_DRIVE=$1

if [ "${SD_DRIVE}" = "/dev/sda" ]; then
	echo -e "\033[1;31mnot use /dev/sda\e[m"
	exit 1
fi

if [ "`whoami`" != "root" ]; then
	echo -e "\033[1;31mneed root privilege to format the sdcard. put sudo as below.\e[m"
	echo -e "\033[1;31m$ sudo ./mkrootfs.sh ${SD_DRIVE}\e[m"
	exit 1
fi


dd if=/dev/zero of=$SD_DRIVE bs=1024 count=1024
sync

SIZE=`fdisk -l $SD_DRIVE | grep Disk | grep bytes | awk '{print $5}'`
# SIZE=`fdisk -l $SD_DRIVE | grep Platte | grep Byte | awk '{print $5}'`

echo DISK SIZE - $SIZE bytes

CYLINDERS=`echo $SIZE/255/63/512 | bc`

echo CYLINDERS - $CYLINDERS

PARTITION1=${SD_DRIVE}1
if [ -b ${PARTITION1} ]; then
	umount ${PARTITION1}
fi

PARTITION2=${SD_DRIVE}2
if [ -b ${PARTITION2} ]; then
	umount ${PARTITION2}
fi

PARTITION3=${SD_DRIVE}3
if [ -b ${PARTITION3} ]; then
	umount ${PARTITION3}
fi

{
echo 1,9,0x0C,*
echo 9,,L
} | sfdisk -D -H 255 -S 63 -C $CYLINDERS --force $SD_DRIVE

sleep 10

if [ -b ${PARTITION1} ]; then
	umount ${PARTITION1}
	mkfs.vfat -F 32 -n "boot" ${PARTITION1}
else
	echo "Cant find boot partition in /dev"
fi

if [ -b ${PARTITION2} ]; then
	umount ${PARTITION2}
	mkfs.ext4 -L "rootfs" ${PARTITION2}
else
	echo "Cant find rootfs partition in /dev"
fi

sync
echo "await formatting ..."
sleep 2
cd sd_fuse/tiny4412/
./sd_fusing.sh $SD_DRIVE
