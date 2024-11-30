#!/bin/sh
printf "Name the disk on which to install arch (ex /dev/sda): " >&2
read -r option
printf '%s\n' "$option"
