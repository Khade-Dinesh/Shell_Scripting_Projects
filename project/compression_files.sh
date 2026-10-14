#!/bin/bash

# date :Tue Oct 13 12:54:04 PM IST 2026


# Variables

dir=/var/log
dest=$HOME/mydir/project
run=0
if [[ ! -d "$dir" ]];
then
	echo " Source Directory not exit "
	exit 1
fi

# Destination Directory exist check...

if [[ ! -d  "$dest" ]];
then
	echo "Directory not exist creating...."
	mkdir "$dest"
fi



# Find file geater than 1kb and compress thim

for i in `sudo find $dir -type f -size +1M -size -5M -name "*.log"`
do
	if [[ $run -eq 0 ]];
	then
		echo "[$(date)] archiving $i  ==> $dest"

		sudo gzip $i || exit 1
		sudo mv $i.gz $dest || exit 1
	fi
done



