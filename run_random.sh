#!/bin/bash

cd /home/Desktop/whatsapp_tender_bot

source venv/bin/activate

RANDOM_DELAY=$((RANDOM % 660))

RUN_TIME=$(date -d "+$RANDOM_DELAY minutes" "+%Y-%m-%d %H:%M:%S")

echo "Today's selected execution time: $RUN_TIME" >> cron.log

sleep ${RANDOM_DELAY}m

echo "Starting bot at $(date)" >> cron.log

python3 main.py >> cron.log 2>&1
