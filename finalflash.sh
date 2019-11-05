#!/bin/bash

# This script is inteded to be a linux version of 'Makeinstall.py" there for it should be executerd 
# from same directory /home/user/Downloads/gibMacOS-master/

RED="\033[1;31m"
NOCOLOR="\033[0m"
YELLOW="\033[01;33m"
set -e
# Checking for root
if [[ $EUID -ne 0 ]]; then
echo -e "${RED}THIS SCRIPT MUST BE RUN AS ROOT${NOCOLOR}" 
exit 1
fi
# Installing dmg2img
echo -e "${YELLOW}WE NEED TO INSTALL SOME IMPORTANT TOOLS TO PROCEED${NOCOLOR}"

# Identifying distro
source /etc/os-release

if [[ $ID = "ubuntu" ]]; then
apt install dmg2img

elif [[ $ID = "fedora" ]]; then
dnf install dmg2img

elif [[ $ID = "Arch Linux" ]]; then
pacman -S dmg2img
else
echo -e "${RED}YOUR DISTRO IS NOT SUPPORTED!!${NOCOLOR}"
exit 1 
fi

# Extracting the iso file with dmg2img 
if cd "$(dirname "$(find ./ -name "BaseSystem.dmg")")"
then echo -e "${YELLOW}EXTRACTING base.iso FROM BaseSystem.dmg!${NOCOLOR}"
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
echo -e "${RED}WARNING!!! SELECTING THE WRONG DISK MAY WIPE YOUR PC AND ALL DATA DO IT AT YOUR OWN RISK!!!${NOCOLOR}"
echo -e "${YELLOW}PLEASE SELECT THE USB-DRIVE!${NOCOLOR}"
select choice in "${lines[@]}"; do
  [[ -n $choice ]] || { echo "Invalid choice. Please try again." >&2; continue; }
break # valid choice was made; exit prompt.
done

# Split the chosen line into ID and serial number.
read -r id sn unused <<<"$choice"
 
echo -e "${YELLOW}COPYING base.iso TO USB-DRIVE!${NOCOLOR}" 
dd bs=4M if=base.iso of=/dev/$id status=progress oflag=sync

umount $(echo /dev/$id)2 || :
sleep 5s

rm -rf base.iso

# Create EFI partition for clover or opencore
fdisk /dev/$id <<EOF
n
2


t
2
1

w
EOF
sleep 5s

# Format the EFI partition for clover or opencore
# and mount it in the /mnt 
mkfs.fat -F 32 $(echo /dev/$id)2
umount $(echo /dev/$id)2 || :
mount -t vfat  $(echo /dev/$id)2 /mnt/ -o rw,umask=000
sleep 5s 
 
# Install opencore
echo -e "${YELLOW}INSTALLING OpenCore!!${NOCOLOR}"
sleep 3s
wget https://files.amd-osx.com/OpenCore-0.5.2-RELEASE.zip
chmod +x OpenCore-0.5.2-RELEASE.zip
unzip OpenCore-0.5.2-RELEASE.zip -d /mnt/
sleep 5s
rm -rf OpenCore-0.5.2-RELEASE.zip 
umount $(echo /dev/$id)2 
mount $(echo /dev/$id)2 /mnt
echo -e "${YELLOW}INSTALLATION FINISHED, OPEN /mnt AND EDIT OC FOR YOUR MACHINE${NOCOLOR}"

# Special thanks to Scooby-Chan for helping writing the script and testing. 
# and ill slap your face for testing as well.
