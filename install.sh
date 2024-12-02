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

printf "UEFI or Legacy BIOS?: " >&2
read -r bootmode
printf '%s\n' "$bootmode"

printf "Hostname: " >&2
read -r hostname
printf '%s\n' "$hostname"







diskpasswd=$(collect_password "Enter the password for disk encryption: ")

# sfdisk ... or parted?
# should ask for all required user input from the beginning then run all the things

# https://stackoverflow.com/questions/12150116/how-to-script-sfdisk-or-parted-for-multiple-partitions
sfdisk $disk

mkfs.fat -F32 "$bootpartition"
mkfs.swap "$swappartition"
cryptsetup luksFormat "$encryptedpartition"
cryptsetup open "$encryptedpartition" unencryptedpartition

mount /dev/mapper/unencryptedpartition /mnt
mkdir /mnt/boot
mount "$bootpartition" /mnt/boot
swapon "$swappartition"









# investigate further how to use syslinux with
# with the encrypted drive - probably just
# same kind of operation as with grub
if [ $bootmode == "UEFI" ]; then
	efibootmgr syslinux ...
fi
pacstrap -K /mnt base linux linux-firmware neovim lvm2

genfstab -U /mnt >> /mnt/etc/fstab

arch-chroot /mnt bash
ln -sf /usr/share/zoneinfo/America/Chicago /etc/localtime
hwclock --systohc

printf 'LANG=en_US.UTF-8' > /etc/locale.conf
locale-gen
printf '%s' "$hostname" > /etc/hostname


