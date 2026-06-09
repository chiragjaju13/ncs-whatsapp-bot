#!/bin/bash

# Define execution path anchors
TARGET_DIR="Desktop/whatsapp_tender_bot"
cd "$TARGET_DIR" || exit 1

# Activate the local virtual python sandbox environment
source venv/bin/activate

# Generate random minute window allocation boundaries (0 to 659 minutes)
RANDOM_DELAY=$((RANDOM % 660))
RUN_TIME=$(date -d "+$RANDOM_DELAY minutes" "+%Y-%m-%d %H:%M:%S")

# Create initial log framework record inside the project directory root
echo "==========================================================" >> bash_cron.log
echo "📅 Event Registered via Crontab Layer on: $(date)" >> bash_cron.log
echo "🎯 Random window locked. Python script will fire at: $RUN_TIME" >> bash_cron.log
echo "==========================================================" >> bash_cron.log

# Enforce script layout suspension 
sleep ${RANDOM_DELAY}m

# Execute scraping cycle, all runtime tracking stdout/stderr handles are captured by Python's Internal DualLogger
python3 main.py