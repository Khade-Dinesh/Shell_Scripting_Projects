#!/bin/bash

HOSTNAME=$1
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
LOG_FILE="/home/dinesh-khade/mydir/scripts/project/network.log"

if [[ "$#" -ne 1 ]];
then 
	echo "USAGE: "$0" <HOSTME/IP>"
	exit 1
fi

# Check host is reachable or not

if ping -c 2 "$HOSTNAME" > /dev/null 2>&1; then
	echo "$HOSTNAME is reachable"

# check HTTP status  

CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 -L "https://$HOSTNAME")

if [[ $CODE -eq 200 ]];
then
	echo "Website is working"
	RESULT="SUCCESS - HTTP $CODE"

else
	echo "Website response: HTTP $CODE"
	RESULT="HTTP $CODE"

fi

else 
	echo "$HOSTNAME is not reachable"
	RESULT="host unrechable"
fi

# save result in log

echo "$TIMESTAMP $HOSTNAME  $RESULT" >> "$LOG_FILE"

echo "result saved in $LOG_FILE"

