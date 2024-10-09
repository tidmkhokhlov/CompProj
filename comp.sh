#!/bin/sh

SCRIPT_DIR="$(dirname "$0")"
LOG_DIR="$SCRIPT_DIR/log"
BACKUP_DIR="$SCRIPT_DIR/backup"

#env
if [ ! -d "$LOG_DIR" ]; 
then
  mkdir "$LOG_DIR"
fi
dd if=/dev/zero of=env.img bs=1M count=100
mkfs.ext4 env.img
sudo mount -o loop env.img "$LOG_DIR"
sudo chmod 777 "$LOG_DIR"
rm -rf "$LOG_DIR"/lost+found
rm env.img
if [ ! -d "$BACKUP_DIR" ]; 
then
  mkdir "$BACKUP_DIR"
fi

#reading X
echo -e "\e[4mEnter X ammount.\e[0m"
read X
D= $X * 0.7

#reading log
Y= du -s "$LOG_DIR" | awk '{print $1}'
# echo $Y

#main condition
if [$Y -le $D]
then
	#archiving
	find "$LOG_DIR" -type f -printf '%T+ %p\n' | sort | head -n $Y-$D | cut -d' ' -f2- | tar -czf "$BACKUP_DIR"$(date +'%Y-%m-%d_%H-%M-%S').tar.gz -T -
	echo -e "\e[42mLog Archived\e[0m"
	#removing files in "$LOG_DIR"
	sudo rm -rf "$LOG_DIR"/*
	#backup moving
	mv "$BACKUP_DIR"$(date +'%Y-%m-%d_%H-%M-%S').tar.gz "$BACKUP_DIR"
	echo -e "\e[42mArchive moved\e[0m"
fi

#unmounting limited folder
sudo umount "$LOG_DIR"
echo -e "$LOG_DIR folder \e[4munmounted\e[0m."


