#!/bin/bash

# Check user running script with root or sudo access.
if [[ "$UID" -ne 0 ]];
then 
	echo "TO run this script need sudo access or root permission"
	exit 1
fi

# Check user passed username as 1st argument and other argument take as comment
if [[ "$#" -lt 1 ]];
then
	echo "USAGE: "$0" <USERNAME> <COMMENNT>"
	echo "create a user name with USER_NAME and comment with COMMENT"
	exit 1
fi

# Store first argument as user name
USER_NAME=$1

# check in case of more than one argument store it as account comments

shift 
COMMENT="$@"

# Create a password
PASSWORD=$(openssl rand -base64 18)

# Create the user
useradd -c "$COMMENT" -s /bin/bash -m  $USER_NAME


# Check if user successfully created or not
if [[ "$?" -ne 0 ]];
then
	echo "User account not created : "
	exit 1
fi

# Set the password for the user 
echo "$USER_NAME:$PASSWORD" | sudo chpasswd 

# Check  if password successfully set or not
if [[ "$?" -ne 0 ]];
then
	echo "Password no set for $USER_NAME"
	exit 1
fi

# Force Password change on first login

sudo chage -d 0 "$USER_NAME"

# Display the username, password, and the host where the user was created.

echo " "
echo "USER_NAME: $USER_NAME"
echo " "
echo "PASSWORD: $PASSWORD"
echo " "
echo "hostname $(hostname)"



