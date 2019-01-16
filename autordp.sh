#!/bin/bash

# This script will login to a users "normal" Windows
# PC if they are logged in elsewhere on the network


# gather credentials

clear
echo
echo "Sitewide hotdesk login"
echo ----------------------

unset ADUSERNAME
echo -n "Username: "
read ADUSERNAME

unset ADPASSWORD
prompt="Password: "
while IFS= read -p "$prompt" -r -s -n 1 char
do
    if [[ $char == $'\0' ]]
    then
        break
    fi
    prompt='*'
    ADPASSWORD+="$char"
done


# find IP for this users PC
cd /tmp
rm logincheck.txt 2> /dev/null
wget https://ServerWithDumpOfLogins/logincheck/logincheck.txt --http-user=logincheck --password=SecretPassword -q --ca-certificate=/location/of/your/enterprise/root/public/certificate.crt

USERSIP=$(grep $ADUSERNAME logincheck.txt | egrep -o -m 1 "\;[0-9].*$" | cut -c2-)

# if we can't find their PC throw an error
if [ -z "$USERSIP" ]
   then
     echo
     echo No active workstation found!
     echo You must be logged in to a Windows PC elsewhere.
     echo "(press any key to retry)"
     read -r -s -n 1 char
     /home/hotdesk/autordp.sh
fi

# attempt to login to PC
echo
echo
sudo nice -n -15 xfreerdp /size:1920x1080 /network:broadband /u:$ADUSERNAME /p:$ADPASSWORD /d:PI /f /cert-ignore /v:$USERSIP
RDPERROR=$?



# Good connection, so start again
if [ 11 == $RDPERROR ] || [ 0 == $RDPERROR ]
   then 
     /home/hotdesk/autordp.sh
fi


# Something went wrong, so stop and let people see the error
echo "(press any key to retry)"
read -r -s -n 1 char
/home/hotdesk/autordp.sh
