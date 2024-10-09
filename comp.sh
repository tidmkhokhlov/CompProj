#!/bin/sh

SCRIPT_DIR="$(dirname "$0")" # Получаем директорию скрипта
LOG_DIR="$SCRIPT_DIR/log"
BACKUP_DIR="$SCRIPT_DIR/backup"
MAX_SIZE=$((2 * 1024 * 1024 * 1024))  # 2 ГБ в байтах
THRESHOLD_SIZE=$((MAX_SIZE * 70 / 100))  # 70% от 2 ГБ

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

#reading log
CURRENT_SIZE=$(du -sb "$LOG_DIR" | awk '{print $1}')

#main condition
if [ "$CURRENT_SIZE" -ge "$THRESHOLD_SIZE" ];
then
	#archiving
	echo "Папка $LOG_DIR заполнена на $(($CURRENT_SIZE / 1024 / 1024)) MB. Начинаю архивирование..."

	N=5
    OLD_FILES=$(ls -t "$LOG_DIR" | tail -n "$N")

	if [ -z "$OLD_FILES" ]; then
        echo "Нет файлов для архивирования."
        exit 0
    fi

	TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    ARCHIVE_FILE="$BACKUP_DIR/archive_$TIMESTAMP.tar.gz"

    tar -czf "$ARCHIVE_FILE" -C "$LOG_DIR" $OLD_FILES

	echo -e "\e[42mLog Archived\e[0m"
	#removing files in "$LOG_DIR"
	for file in $OLD_FILES; do
        rm "$LOG_DIR/$file"
    done

    echo "Файлы архивированы в $ARCHIVE_FILE и удалены из $LOG_DIR."

	echo -e "\e[42mArchive moved\e[0m"
else
    echo "Папка $LOG_DIR заполнена на $(($CURRENT_SIZE / 1024 / 1024)) MB. Архивирование не требуется."
fi

#unmounting limited folder
sudo umount "$LOG_DIR"
echo -e "$LOG_DIR folder \e[4munmounted\e[0m."


