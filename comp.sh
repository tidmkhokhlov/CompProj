#!/bin/sh

#env
if [ ! -d log ]; 
then
  mkdir log
fi
mkdir log
dd if=/dev/zero of=env.img bs=1M count=100
mkfs.ext4 env.img
sudo mount -o loop env.img log
sudo chmod 777 log
rm -rf log/lost+found
rm env.img
if [ ! -d back ]; 
then
  mkdir back
fi

#reading X
echo -e "\e[4mEnter X ammount.\e[0m"
read X
D= $X * 0.7

#reading log
Y= du -s log | awk '{print $1}'
# echo $Y

#main condition
if [$Y -le $D]
then
	#archiving
	sudo tar -czf back.tar.gz log
	echo -e "\e[42mLog Archived\e[0m"
	#removing files in log
	sudo rm -rf log/*
	#backup moving
	mv back.tar.gz back
	echo -e "\e[42mArchive moved\e[0m"
fi

#unmounting limited folder
sudo umount log
echo -e "Log folder \e[4munmounted\e[0m."


