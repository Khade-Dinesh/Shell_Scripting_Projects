#!/bin/bash


set -euo pipefail

# Read log file path from argument.

Log_file=$1


# Validate Argument 

if [[ $# -ne 1 ]];
then
	echo "Usage: "$0" <path/to/logfile>"
	exit 1
fi

# Check if file exists

if [[ ! -f "$Log_file" ]];
then
	echo "LOG_FILE does not exit"
	exit 1
fi

# Count total lines

Total_line=$(wc -l < "$Log_file")


# Count ERROR, WARNING and INFO

ERRORS=$(grep -ic "error"  "$Log_file" || true )

WARNING=$(grep -ic "WARNING" "$Log_file" || true)

INFO=$(grep -ic "INFO" "$Log_file" || true)

# Save error message

Error_file="/home/dinesh-khade/mydir/scripts/auth.log"

grep -i "error" "$Log_file" >> "$Error_file" || true 

# Summary 
DATE=$(date +%Y-%m-%d_%H-%M-%S)

echo "========================== LOG ANALYZER REPORT ================================"
echo " "
echo "DATE : $DATE"
echo " "
echo "Log File: $Log_file"
echo " "
echo "Total Lines in File: $Total_line"
echo " "
echo "TOTAL ERRORS: $ERRORS"
echo " "
echo "TOTAL WARNINGS: $WARNING"
echo " "
echo "TOTAL INFO: $INFO"
echo " "
echo "Error Report: $Error_file"
echo "==============================================================================="



