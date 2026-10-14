#!/bin/bash

# Get hostname and timestamp

Hostname=$(hostname)
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)

# check Disk usage 

Disk=$(df -h | grep "dev/sda2" | awk '$5+=0 {print $5}')

# check ram usage

total_ram=$(free | awk '/Mem:/ {print $2}')
available_ram=$(free | awk '/Mem:/ {print $7}')

used_ram=$((total_ram - available_ram))

ram_percentage=$(awk -v used="$used_ram" -v total="$total_ram" \
    'BEGIN {printf "%.2f", (used/total)*100}')

# check cpu usage 

CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8 "%"}')

# Print health report 


echo "=========== SERVER HEALTH REPORT ============"

      echo "HOSTNAME: $Hostname"

      echo " "

      echo "DATE: $TIMESTAMP"

      echo " "

      echo "Disk Usage: $Disk"
      echo " "
      echo "RAM Usage: $ram_percentage"
      echo " "
      echo "CPU Usage: $CPU"
      echo " "


    
      if [[ "$Disk" -ge 80  && "$ram_percentage" -ge 80 ]];
      then
	      echo "CRITICAL: DISK IS $DISK% FULL"
	      echo "CRTICAL: MEMOERY SPACE $ram_percentage% FULL"
      else
	      echo "STATUS: HEALTHY"
      fi 
      echo "============================================================="
     
	      
