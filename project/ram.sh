#!/bin/bash

total_ram=$(free | awk '/Mem:/ {print $2}')
available_ram=$(free | awk '/Mem:/ {print $7}')

used_ram=$((total_ram - available_ram))

ram_percentage=$(awk -v used="$used_ram" -v total="$total_ram" \
    'BEGIN {printf "%.2f", (used/total)*100}')

echo "RAM Usage: ${ram_percentage}%"
