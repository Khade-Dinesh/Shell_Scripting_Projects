#!/bin/bash

DATE=$(date "+%Y-%m-%d %H:%M:%S")
echo "Today is : $DATE"
#Script should be execute with sudo/root access.

if [[ "${UID}" -ne 0 ]];
then
	echo "Please run script with sudo or root access"
	exit 1
fi

#User should provide atleast one argument as username else guide him.

if [[ $# -lt 1 ]];
then
	echo "Usage ${0} USER_NAME [COMMENT]...."
	echo "create user with name USER_NAME and comments field of comment"
	exit 1
fi

#Store 1st argument as user name 

USER_NAME=${1}


#In case of more than one argument store it as account comments.
shift
COMMENT="${@}"


#create a password
PASSWORD=$(date +%s%N)


#Create the user 
useradd -c "$COMMENT" -m $USER_NAME

#Check if user is successfully created or not 
if [[ $? -ne 0 ]];
then
	echo "unable to create user"
	exit 1
fi

#Set the password for the user 

echo "$USER_NAME:$PASSWORD" | chpasswd

#Check if password is successfully set or not 
if [[ $? -ne 0 ]];
then
	echo "Password could not be set"
	exit 1
fi

#Force password change on first login.

passwd -e $USER_NAME

echo "User name is : $USER_NAME"
echo "Password is : $PASSWORD"
echo "Hostname is : $HOSTNAME"

echo "congratulations"
