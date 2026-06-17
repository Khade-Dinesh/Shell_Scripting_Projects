#!/bin/bash
#$Revision:001$
#$Wed Jun 17 03:22:19 PM IST 2026$


#Variables

BASE=/home/dinesh-khade/my_project
DAYS=1
DEPTH=1
RUN=1

#Check if the directory is present or not 

if [ ! -d $BASE ]
then 
	echo "directory does not exist: $BASE"
	exit 1
fi 

#Create "archive-files" folder if not present

if [ ! -d $BASE/archive-files ]
then
	mkdir $BASE/archive-files
fi

# Find the list of files larger than 500KB

for i in $(find $BASE -maxdepth $DEPTH -type f -size +1k)
do
	if [ $RUN -eq 1 ]
	then
		echo "[$(date "+%Y-%m-%d %H:%M:%S")] archiving $i ==> $BASE/archive-files"
		gzip $i || exit 1
		mv $i.gz $BASE/archive-files || exit 1
	fi
done 
