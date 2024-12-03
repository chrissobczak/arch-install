#!/bin/sh
lsblk -f
printf "Name the disk on which to install arch (ex /dev/sda): " >&2
read -r DISK
printf "UEFI or BIOS?: " >&2
read -r BOOTMODE
printf "Hostname: " >&2
read -r HOSTNAME
printf "Username: " >&2
read -r USERNAME

# Format disk
# https://stackoverflow.com/questions/12150116/how-to-script-sfdisk-or-parted-for-multiple-partitions
sfdisk $disk < layout.sfdisk
mkfs.fat -F32 "${DISK}1"
mkfs.swap "${DISK}2"
cryptsetup luksFormat "${DISK}3"
cryptsetup open "${DISK}3" unencryptedpartition
mkfs.ext4 /dev/mapper/unencryptedpartition

# Mount partitions
mount /dev/mapper/unencryptedpartition /mnt
mkdir /mnt/boot
mount "${DISK}1" /mnt/boot
swapon "${DISK}2"

case $BOOTMODE in
	UEFI) additionalpackages="efibootmgr";;
	BIOS) additionalpackages="mtools gptfdisk";;
	*) "No valid bootmode provided";;
esac

pacstrap -K /mnt base linux linux-firmware lvm2 cryptsetup grub $additionalpackages
genfstab -U /mnt >> /mnt/etc/fstab

# Chroot into the new machine
arch-chroot /mnt
ln -sf /usr/share/zoneinfo/America/Chicago /etc/localtime
hwclock --systohc
printf "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
printf 'LANG=en_US.UTF-8' > /etc/locale.conf
printf '%s' "$HOSTNAME" > /etc/hostname

printf '127.0.0.1 localhost' > /etc/hosts
printf '::1 localhost' >> /etc/hosts
printf "127.0.1.1 $HOSTNAME.localdomain $HOSTNAME" >> /etc/hosts

printf '%s\n' "Enter a password for the root user: "
passwd
useradd -G wheel -m $USERNAME
printf '%s\n' "Enter a password for $USERNAME: "
passwd $USERNAME

sed -i 's|^HOOKS=(|HOOKS=(lvm2 encrypt |g' /etc/mkinitcpio.conf
sed -i "s|^GRUB_CMDLINE_LINUX_DEFAULT.*$|GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel3 quiet cryptdevice=UUID=$(lsblk -o UUID "${DISK}3" | tail -n 1):cryptlvm root=UUID=$(lsblk -o UUID /dev/mapper/unencryptedpartition | tail -n 1) iomem=relaxed\"|g" /etc/default/grub
case $BOOTMODE in
	UEFI) grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=grub;;
	BIOS) grub-install $DISK;;
	*) "No valid bootmode provided";;
esac
grub-mkconfig -o /boot/grub/grub.cfg

printf '%s\n' "Base system is now installed, exit the chroot and reboot the system (be sure to remove installation media"
