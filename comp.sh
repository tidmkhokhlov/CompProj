#!/bin/sh

SCRIPT_DIR="$(dirname "$0")" # Получаем директорию скрипта
LOG_DIR="$SCRIPT_DIR/log"
BACKUP_DIR="$SCRIPT_DIR/backup"

intro() 
{
    echo -e "

 _____ ________  _____________________ _____   ___ 
/  __ \  _  |  \/  || ___ \ ___ \ ___ \  _  | |_  |
| /  \/ | | | .  . || |_/ / |_/ / |_/ / | | |   | |
| |   | | | | |\/| ||  __/|  __/|    /| | | |   | |
| \__/\ \_/ / |  | || |   | |   | |\ \\ \_/ /\__/ /
 \____/\___/\_|  |_/\_|   \_|   \_| \_|\___/\____/ 
                    ______                         
                   |______|                        
    "

}

# Функция лимитирования папки
limitation() {
    dd if=/dev/zero of=env.img bs=1M count=$MAX_SIZE
    mkfs.ext4 env.img
    sudo mount -o loop env.img "$LOG_DIR"
    sudo chmod 777 "$LOG_DIR"
    rm -rf "$LOG_DIR"/lost+found
    rm env.img
}

intro
# Получаем MAX_SIZE от пользователя
echo -e "Enter \e[4mMAX_SIZE (MB)\e[0m of the folder."
read MAX_SIZE

# Создание папок, если они не существуют
mkdir -p "$LOG_DIR" "$BACKUP_DIR"

#Ограничение папки
echo -e "The folder is going to be limited by \e[4m$MAX_SIZE Mb\e[0m. Y/n?"
read ANSWER
if [ $ANSWER = "Y" ]; then

    # Сохранение имеющихся файлов
    if [ $(ls -1 "$LOG_DIR" | wc -l) != 0 ]; then
        tar -czf "log_buffer.tar.gz" -C "$LOG_DIR" . # Архивируем файлы
        rm -f "$LOG_DIR"/*
        limitation
        tar -xzf log_buffer.tar.gz -C "$LOG_DIR" # Разархивируем обратно
        rm log_buffer.tar.gz
    else
        limitation
    fi
else
    echo "Is the folder already limited? Y/n?"
    read ANSWER
    if [ $ANSWER != "Y" ]; then
        echo -e "\e[41mScript execution stopped.\e[0m"
        exit 1
    fi
fi

# Получаем THRESHOLD_SIZE
echo -e "Enter the folder \e[4mfill percentage\e[0m."
read THRESHOLD_PERCENT
THRESHOLD_SIZE=$(($MAX_SIZE * $THRESHOLD_PERCENT / 100))

# Получение текущего размера папки в байтах
CURRENT_SIZE=$(du -sb "$LOG_DIR" | awk '{print $1}')

# Проверка заполнения
if [ "$CURRENT_SIZE" -ge "$(($THRESHOLD_SIZE * 1024 * 1024))" ]; then
    echo "Folder $LOG_DIR is full by $(($CURRENT_SIZE / 1024 / 1024)) MB. Starting archiving..."

    # Получаем N
    echo -e "There are \e[4m$(ls -1 "$LOG_DIR" | wc -l)\e[0m files in the folder. How many to archive?"
    read N

    # Находим N старейших файлов
    OLD_FILES=$(ls -t "$LOG_DIR" | tail -n "$N")
    if [ -z "$OLD_FILES" ]; then
        echo "No files to archive."
        
        #Отключение ограниченной папки
        echo -e "The folder is going to be unlimited. \e[4mAll files will be deleted\e[0m. Y/n?"
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
echo -e "The folder is going to be unlimited. \e[4mAll files will be deleted\e[0m. Y/n?"
read ANSWER
if [ $ANSWER = "Y" ]; then
    sudo umount "$LOG_DIR"
    echo -e "$LOG_DIR folder \e[4munmounted\e[0m."
else
    exit 1
fi
