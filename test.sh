#!/bin/bash

SCRIPT_DIR="$(dirname "$0")"
LOG_DIR="$SCRIPT_DIR/log"
BACKUP_DIR="$SCRIPT_DIR/backup"

mkdir -p "$LOG_DIR" "$BACKUP_DIR"

rm -rf "$LOG_DIR"/* "$BACKUP_DIR"/*

for i in {1..10}; do
    dd if=/dev/zero of="$LOG_DIR/testfile$i.txt" bs=200M count=1 > /dev/null 2>&1
done

# Тест 1: Проверка архивирования при заполниность > 70%
echo "Запуск теста 1..."
