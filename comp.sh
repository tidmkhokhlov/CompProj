#!/bin/sh

SCRIPT_DIR="$(dirname "$0")" # Получаем директорию скрипта
LOG_DIR="$SCRIPT_DIR/log"
BACKUP_DIR="$SCRIPT_DIR/backup"
MAX_SIZE=$((2 * 1024 * 1024 * 1024))  # 2 ГБ в байтах
THRESHOLD_SIZE=$((MAX_SIZE * 70 / 100))  # 70% от 2 ГБ

# Проверка аргументов
if [ $# -ne 1 ]; then
    echo "Usage: $0 <threshold_in_%>"
    exit 1
fi

# Создание папок, если они не существуют
mkdir -p "$LOG_DIR" "$BACKUP_DIR"

# Получение текущего размера папки в байтах
CURRENT_SIZE=$(du -sb "$LOG_DIR" | awk '{print $1}')

# Проверка заполнения
if [ "$CURRENT_SIZE" -ge "$THRESHOLD_SIZE" ]; then
    echo "Folder $LOG_DIR is full by $(($CURRENT_SIZE / 1024 / 1024)) MB. Starting archiving..."

    # Находим N старейших файлов
    N=5
    OLD_FILES=$(ls -t "$LOG_DIR" | tail -n "$N")
    if [ -z "$OLD_FILES" ]; then
        echo "No files to archive."
        exit 0
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
