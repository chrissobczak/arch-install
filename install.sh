#!/bin/sh


# should ask for all required user input from the beginning then run all the things

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

# https://stackoverflow.com/questions/12150116/how-to-script-sfdisk-or-parted-for-multiple-partitions
sfdisk $disk < layout.sfdisk

mkfs.fat -F32 "${disk}1"
mkfs.swap "${disk}2"
cryptsetup luksFormat "${disk}3"
cryptsetup open "${disk}3" unencryptedpartition
mkfs.ext4 /dev/mapper/unencryptedpartition

mount /dev/mapper/unencryptedpartition /mnt
mkdir /mnt/boot
mount "${disk}1" /mnt/boot
swapon "${disk}2"



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


