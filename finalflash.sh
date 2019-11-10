#!/bin/bash

# This script is inteded to be a linux version of 'Makeinstall.py" there for it should be executerd 
# from same directory /home/user/Downloads/gibMacOS-master/

RED="\033[1;31m"
NOCOLOR="\033[0m"
YELLOW="\033[01;33m"
set -e
# Checking for root
if [[ $EUID -ne 0 ]]; then
echo -e "${RED}THIS SCRIPT MUST RUN AS ROOT${NOCOLOR}" 
exit 1
fi
# Installing dmg2img
# for arch also wget and unzip
echo -e "\e[3mWE NEED TO INSTALL SOME IMPORTANT TOOLS TO PROCEED!\e[0m"

# Identifying distro
source /etc/os-release

if [[ $ID = "ubuntu" ]]; then
yes | apt install dmg2img

elif [[ $ID = "fedora" ]]; then
yes | dnf install dmg2img

elif [[ $ID = "arch" ]]; then
yes | pacman -S dmg2img;yes | pacman -S unzip;yes | pacman -S wget

else
echo -e "${RED}YOUR DISTRO IS NOT SUPPORTED!!${NOCOLOR}"
exit 1 
fi

# Extracting the iso file with dmg2img 
if cd "$(dirname "$(find ./ -name "BaseSystem.dmg")")"
then echo -e "\e[3mEXTRACTING base.iso FROM BaseSystem.dmg!\e[0m"
sleep 3s
dmg2img BaseSystem.dmg base.iso 
else 
echo -e "${RED}BaseSystem.dmg NOT FOUND DOWNNLOAD IT AND TRY AGAIN!${NOCOLOR}"
exit 1
fi

# Print disk devices
# Read command output line by line into array ${lines [@]}
# Bash 3.x: use the following instead:
#   IFS=$'\n' read -d '' -ra lines < <(lsblk --nodeps -no name,size | grep "sd")
readarray -t lines < <(lsblk --nodeps -no name,size | grep "sd")

# Prompt the user to select one of the lines.
echo -e "${RED}WARNING!!! SELECTING THE WRONG DISK MAY WIPE YOUR PC AND ALL DATA!!!${NOCOLOR}"
echo -e "${YELLOW}\e[3mPLEASE SELECT THE USB-DRIVE!\e[0m${NOCOLOR}"
select choice in "${lines[@]}"; do
  [[ -n $choice ]] || { echo "INVALID CHOICE. PLEASE TRY AGAIN." >&2; continue; }
break # valid choice was made; exit prompt.
done

# Split the chosen line into ID and serial number.
read -r id sn unused <<<"$choice"
 
echo -e "\e[3mCOPYING base.iso TO USB-DRIVE!\e[0m" 
dd bs=4M if=base.iso of=/dev/$id status=progress oflag=sync
umount $(echo /dev/$id)1 > /dev/null 2>&1 || : 
umount $(echo /dev/$id)2 > /dev/null 2>&1 || : 
sleep 5s

rm -rf base.iso

# Create EFI partition for clover or opencore
(
echo "n"
echo "2"
echo ""
echo ""
echo "t"
echo "2"
echo "1"
sleep 5s
echo "w") | fdisk /dev/$id > /dev/null 2>&1

sleep 3s

# Format the EFI partition for clover or opencore
# and mount it in the /mnt 
mkfs.fat -F 32 $(echo /dev/$id)2 > /dev/null 2>&1
mount -t vfat  $(echo /dev/$id)2 /mnt/ -o rw,umask=000 
sleep 5s 
 
# Install opencore
echo -e "\e[3mINSTALLING OpenCore!!\e[0m"
sleep 3s
wget https://files.amd-osx.com/OpenCore-0.5.2-RELEASE.zip > /dev/null 2>&1
unzip OpenCore-0.5.2-RELEASE.zip -d /mnt/ > /dev/null 2>&1
sleep 5s
chmod +x /mnt/
rm -rf OpenCore-0.5.2-RELEASE.zip 
umount $(echo /dev/$id)2 
mount $(echo /dev/$id)2 /mnt/
sleep 3s

echo -e "\e[3mINSTALLATION FINISHED, OPEN /mnt AND EDIT OC FOR YOUR MACHINE!!\e[0m"

# Special thanks to Scooby-Chan for helping writing the script and testing. 
# and ill slap your face for testing as well.
