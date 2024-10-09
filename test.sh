#!/bin/bash

SCRIPT_DIR="$(dirname "$0")"
LOG_DIR="$SCRIPT_DIR/log"
BACKUP_DIR="$SCRIPT_DIR/backup"

mkdir -p "$LOG_DIR" "$BACKUP_DIR"

#env
dd if=/dev/zero of=env.img bs=1M count=100
mkfs.ext4 env.img
sudo mount -o loop env.img "$LOG_DIR"
sudo chmod 777 "$LOG_DIR"
rm -rf "$LOG_DIR"/lost+found
rm env.img

rm -rf "$LOG_DIR"/* "$BACKUP_DIR"/*

for i in {1..10}; do
    dd if=/dev/zero of="$LOG_DIR/testfile$i.txt" bs=200M count=1 > /dev/null 2>&1
done

# Тест 1: Проверка архивирования при заполниность > 70%
echo "Запуск теста 1..."


#unmounting limited folder
sudo umount "$LOG_DIR"
echo -e "$LOG_DIR folder \e[4munmounted\e[0m."