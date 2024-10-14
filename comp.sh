#!/bin/sh

SCRIPT_DIR="$(dirname "$0")" # Получаем директорию скрипта
LOG_DIR="$SCRIPT_DIR/log"
BACKUP_DIR="$SCRIPT_DIR/backup"

# Получаем MAX_SIZE от пользователя
echo -e "\e[4mEnter MAX_SIZE of the folder.\e[0m"
read MAX_SIZE

# Получаем THRESHOLD_SIZE
echo -e "\e[4mEnter the folder fill percentage.\e[0m"
read THRESHOLD_PERCENT
THRESHOLD_SIZE=$(($MAX_SIZE * $THRESHOLD_PERCENT / 100))

# Создание папок, если они не существуют
mkdir -p "$LOG_DIR" "$BACKUP_DIR"

#Ограничение папки
echo -e "\e[4mThe folder is going to be limited by $MAX_SIZE Mb. Y/n?\e[0m"
read ANSWER
if [ $ANSWER = "Y" ]; then
    dd if=/dev/zero of=env.img bs=1M count=$MAX_SIZE
    mkfs.ext4 env.img
    sudo mount -o loop env.img "$LOG_DIR"
    sudo chmod 777 "$LOG_DIR"
    rm -rf "$LOG_DIR"/lost+found
    rm env.img
else
    echo -e "\e[4mIs the folder already limited? Y/n?\e[0m"
    read ANSWER
    if [ $ANSWER != "Y" ]; then
        echo -e "\e[41mScript execution stopped.\e[0m"
        exit 1
    fi
fi

# Получение текущего размера папки в байтах
CURRENT_SIZE=$(du -sb "$LOG_DIR" | awk '{print $1}')

# Проверка заполнения
if [ "$CURRENT_SIZE" -ge "$THRESHOLD_SIZE" ]; then
    echo "Folder $LOG_DIR is full by $(($CURRENT_SIZE / 1024 / 1024)) MB. Starting archiving..."

    # Получаем N
    echo -e "\e[4mThere are $(ls -1 "$LOG_DIR" | wc -l) files in the folder. How many to archive?\e[0m"
    read N

    # Находим N старейших файлов
    OLD_FILES=$(ls -t "$LOG_DIR" | tail -n "$N")
    if [ -z "$OLD_FILES" ]; then
        echo "No files to archive."
        
        #Отключение ограниченной папки
        echo -e "\e[4mThe folder is going to be unlimited. All files will be deleted. Y/n?\e[0m"
        read ANSWER
        if [ $ANSWER = "Y" ]; then
            sudo umount "$LOG_DIR"
            echo -e "$LOG_DIR folder \e[4munmounted\e[0m."
            exit 1
        else
            exit 0
        fi
    fi

    # Создание архива
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    ARCHIVE_FILE="$BACKUP_DIR/archive_$TIMESTAMP.tar.gz"
    tar -czf "$ARCHIVE_FILE" -C "$LOG_DIR" $OLD_FILES

    # Удаление архивированных файлов
    for file in $OLD_FILES; do
        rm "$LOG_DIR/$file"
    done

    echo "Files archived in $ARCHIVE_FILE and removed from $LOG_DIR."
else
    echo "$LOG_DIR folder is full by $(($CURRENT_SIZE / 1024 / 1024)) MB. No archiving required."
fi

#Отключение ограниченной папки
echo -e "\e[4mThe folder is going to be unlimited. All files will be deleted. Y/n?\e[0m"
read ANSWER
if [ $ANSWER = "Y" ]; then
    sudo umount "$LOG_DIR"
    echo -e "$LOG_DIR folder \e[4munmounted\e[0m."
else
    exit 1
fi
