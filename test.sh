#!/bin/sh

SCRIPT_DIR="$(dirname "$0")" # Получаем директорию скрипта
LOG_DIR="$SCRIPT_DIR/log"
BACKUP_DIR="$SCRIPT_DIR/backup"

# Создание папок, если они не существуют
mkdir -p "$LOG_DIR" "$BACKUP_DIR"

#Ограничение папки
dd if=/dev/zero of=env.img bs=1M count=2048
mkfs.ext4 env.img
sudo mount -o loop env.img "$LOG_DIR"
sudo chmod 777 "$LOG_DIR"
rm -rf "$LOG_DIR"/lost+found
rm env.img

# Очистка
rm -rf "$LOG_DIR"/* "$BACKUP_DIR"/*

# Генерация тестовых файлов (общий размер = 2 ГБ)
for i in {1..10}; do
    dd if=/dev/zero of="$LOG_DIR/testfile$i.txt" bs=200M count=1 > /dev/null 2>&1
done

# Тест 1: Проверка архивирования при заполнении > 70%
echo "Running test 1..."
initial_count=$(ls -1 "$BACKUP_DIR" | wc -l)
./comp.sh 70
new_count=$(ls -1 "$BACKUP_DIR" | wc -l)

if [ $((new_count - initial_count)) -eq 1 ]; then
    echo -e "\e[42mTest 1 passed: Archive created.\e[0m"
else
    echo -e "\e[41mTest 1 failed: Archive not created.\e[0m"
fi

# Очистка
rm -rf "$LOG_DIR"/*

# Генерация новых файлов (общий размер = 1.4 ГБ)
for i in {1..7}; do
    dd if=/dev/zero of="$LOG_DIR/testfile$i.txt" bs=200M count=1 > /dev/null 2>&1
done

# Тест 2: Проверка архивирования при заполнении = 70%
echo "Running test 2..."
initial_count=$(ls -1 "$BACKUP_DIR" | wc -l)
./comp.sh 70
new_count=$(ls -1 "$BACKUP_DIR" | wc -l)

if [ $((new_count - initial_count)) -eq 0 ]; then
    echo -e "\e[42mTest 2 passed: Archive not created.\e[0m"
else
    echo -e "\e[41mTest 2 failed: Archive should not have been created.\e[0m"
fi

# Тест 3: Проверка, когда заполнение < 70%
echo "Running test 3..."
rm -f "$LOG_DIR"/*  # Удаляем файлы для теста

# Создаем только небольшой файл, чтобы заполнение было < 70% (общий размер = 0.1 ГБ)
dd if=/dev/zero of="$LOG_DIR/smallfile.txt" bs=100M count=1 > /dev/null 2>&1

initial_count=$(ls -1 "$BACKUP_DIR" | wc -l)
./comp.sh 70
new_count=$(ls -1 "$BACKUP_DIR" | wc -l)

if [ $((new_count - initial_count)) -eq 0 ]; then
    echo -e "\e[42mTest 3 passed: Archive not created.\e[0m"
else
    echo -e "\e[41mTest 3 failed: Archive should not have been created.\e[0m"
fi

# Очистка
rm -rf "$LOG_DIR"/*

# Генерация новых файлов
for i in {1..10}; do
    dd if=/dev/zero of="$LOG_DIR/testfile$i.txt" bs=200M count=1 > /dev/null 2>&1
done

# Тест 4: Проверка архивирования N старейших файлов
echo "Running test 4..."
initial_count=$(ls -1 "$BACKUP_DIR" | wc -l)
./comp.sh 70
new_count=$(ls -1 "$BACKUP_DIR" | wc -l)

if [ $((new_count - initial_count)) -eq 1 ]; then
    echo -e "\e[42mTest 4 passed: Archive created.\e[0m"
else
    echo -e "\e[41mTest 4 failed: Archive not created.\e[0m"
fi

#Отключение ограниченной папки
sudo umount "$LOG_DIR"
echo -e "$LOG_DIR folder \e[4munmounted\e[0m."