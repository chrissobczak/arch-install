#!/bin/sh

collect_password() {
	printf $1 >&2
	read -s password
	printf "Enter the same password again to verify: " >&2
	read -s password2
	if [ $password == $password2 ]; then
		$password
	else
		password=$(collect_password $1)
	fi
	return $password
}

lsblk -f
printf "Name the disk on which to install arch (ex /dev/sda): " >&2
read -r disk
printf '%s\n' "$disk"

diskpasswd=$(collect_password "Enter the password for disk encryption: ")




# sfdisk ... or parted?
# should ask for all required user input from the beginning then run all the things

#sfdisk $disk

#mkfs.fat -F32 "$disk1"
#mkfs.swap "$disk2"

#cryptsetup luksFormat "$disk3"

#cryptsetup open
