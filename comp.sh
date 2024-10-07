#!/bin/sh

#env
mkdir log
dd if=/dev/zero of=env.img bs=1M count=100
mkfs.ext4 env.img
sudo mount -o loop env.img log
rm env.img
mkdir back

#reading X
echo "Enter X ammount."
read X
D=$X * 0.7

#reading log
Y=sudo du -s log |awk '{print $1}'
echo $Y

#main condition
if [$Y -le $D]
then
	#archiving
	sudo tar -czf back.tar.gz log
	echo "/log archived"
	#removing files in log
	sudo rm -r log/*
	#backup moving
	mv back.tar.gz back
	echo "archive moved"
fi

#unmounting limited folder
sudo umount log


