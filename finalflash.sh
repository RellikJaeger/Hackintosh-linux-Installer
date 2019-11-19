#!/bin/bash
# Autor: Broly
# License: GNU General Public License v3.0
# https://www.gnu.org/licenses/gpl-3.0.txt
# This script is inteded to create a opencore usb-installer on linux just like 
#'Makeinstall.py" does on windows there for it should be executerd
# from /gibMacOS-master/ directory.
# dependence gibmacos https://github.com/corpnewt/gibMacOS

RED="\033[1;31m"
NOCOLOR="\033[0m"
YELLOW="\033[01;33m"
set -e
func1 (){
  if
  wget https://files.amd-osx.com/OpenCore-0.5.2-RELEASE.zip
  then
    unzip OpenCore-0.5.2-RELEASE.zip -d /mnt/
  else
    echo -e "${RED}Something went wrong!!!${NOCOLOR}"
  fi
  sleep 5s
  chmod +x /mnt/
  rm -rf OpenCore-0.5.2-RELEASE.zip
  umount $(echo /dev/$id)2
  mount -t vfat  $(echo /dev/$id)2 /mnt/ -o rw,umask=000
  sleep 3s
}

partition (){
  # Create EFI partition for clover or opencore
  (
    echo "x"
    echo "e"
    echo "w"
    echo "y") | gdisk /dev/$id
  (
    echo "n"
    echo "2"
    echo ""
    echo ""
    echo "t"
    echo "2"
    echo "1"
    sleep 3s
    echo "w") | fdisk /dev/$id
    sleep 3s
}
# Checking for root
if [[ $EUID -ne 0 ]]; then
  echo -e "${RED}THIS SCRIPT MUST RUN AS ROOT${NOCOLOR}"
  exit 1
fi
# Installing dmg2img + unzip
echo -e "\e[3mWe need to install some important tools to proceed!\e[0m"
sleep 3s
# Identifying distro
source /etc/os-release

if [[ $ID = "ubuntu" ]]; then
  yes | apt install dmg2img

elif [[ $ID = "linuxmint" ]]; then
  yes | apt install dmg2img

elif [[ $ID = "debian" ]]; then
    yes | apt-get install dmg2img;yes | apt-get install unzip;yes | apt-get install wget

elif [[ $ID = "fedora" ]]; then
  yes | dnf install dmg2img

elif [[ $ID = "arch" ]]; then
  yes | pacman -S dmg2img;yes | pacman -S unzip;yes | pacman -S wget

elif [[ $ID = "manjaro" ]]; then
  yes | pacman -S dmg2img;yes | pacman -S unzip;yes | pacman -S wget

else
  echo -e "${RED}YOUR DISTRO IS NOT SUPPORTED!!${NOCOLOR}"
  exit 1
fi

# Extracting the iso file with dmg2img
cd "$(dirname "$(find ./ -name "publicrelease")")"
cd publicrelease
echo -e "${YELLOW}\e[3mPlease select macos version!\n\e[0m${NOCOLOR}"
if select d in */; do test -n "$d" && break; echo -e "${RED}>>> Invalid Selection !${NOCOLOR}"; done
then
  cd "$d" && dmg2img BaseSystem.dmg base.iso
else
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
  [[ -n $choice ]] || { echo -e "${RED}>>> Invalid Selection !${NOCOLOR}" >&2; continue; }
  break # valid choice was made; exit prompt.
done

# Split the chosen line into ID and serial number.
read -r id sn unused <<<"$choice"

echo -e "\e[3mCopying base.iso to usb-drive!\e[0m"
if
dd bs=4M if=base.iso of=/dev/$id status=progress oflag=sync
then
  umount $(echo /dev/$id?*)  || :; sleep 3s
else
  exit 1
fi

partition

# Format the EFI partition for clover or opencore
# and mount it in the /mnt
if
mkfs.fat -F 32 -n EFI $(echo /dev/$id)2
then
  mount -t vfat  $(echo /dev/$id)2 /mnt/ -o rw,umask=000; sleep 3s
else
  exit 1
fi

# Install opencore
echo -e "\e[3mInstalling OpenCore!!\e[0m"
sleep 3s
func1
echo -e "\e[3mInstallation finished, open /mnt and edit oc for your machine!!\e[0m"

# Special thanks to CorpNewt for awsome tool gibmacos
# Scooby-Chan for helping writing the script and testing.
# and ill slap your face for testing as well.
