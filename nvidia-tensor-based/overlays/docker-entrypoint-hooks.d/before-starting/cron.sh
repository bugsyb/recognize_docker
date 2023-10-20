#!/bin/sh
set -eu
echo ------------------------------PHP_MEMORY_LIMIT=$PHP_MEMORY_LIMIT
#export PHP_MEMORY_LIMIT=512M
exec sudo /cron.sh &

