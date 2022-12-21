#!/usr/bin/env bash

source "$(dirname "$0")/utils.sh"

parse_config

while true; do
    if [ "$(prompt_choice "Connect to wifi?" "y" "n")" = "y" ]; then
        read -rp "SSID: " ssid
        read -rp "Passphrase: " passphrase
        iwctl --passphrase "$passphrase" station wlan0 connect "$ssid" || continue
        # IP-address is from Google
        while true; do ping -c 1 142.250.179.206 &>/dev/null && break; done
        break
    else
        break
    fi
done

"$(dirname "$0")"/disk.sh

cp "$(dirname "$0")/filesystem/etc/pacman.conf" /etc/pacman.conf

echo "Ensure the system clock is accurate..."
timedatectl set-ntp true

echo "Updating package keyring..."
pacman-key --populate archlinux
pacman-key --refresh-keys

echo "Install packages..."
pacstrap -K "$mount_path" "${packages[@]}"

echo "Generate an fstab file..."
genfstab -L "$mount_path" >>"$mount_path/etc/fstab"

echo "Setting time zone..."
arch-chroot "$mount_path" ln -sf /usr/share/zoneinfo/Europe/Amsterdam /etc/localtime

echo "Generate /etc/adjtime..."
arch-chroot "$mount_path" hwclock --systohc

echo "Set the root passwd..."
while true; do
    arch-chroot "$mount_path" passwd || continue
    break
done

echo "Creating user..."
arch-chroot "$mount_path" useradd -m "$username"
echo "Give new password for login '$username'..."
while true; do
    arch-chroot "$mount_path" passwd "$username" || continue
    break
done

echo "Copying files..."
rsync -a ./filesystem/ "$mount_path"
rsync -a ./user-home/ "$mount_path/home/bastiaan"
arch-chroot "$mount_path" chown -R "$username:$username" "/home/$username"

echo "Generate the locales..."
arch-chroot "$mount_path" locale-gen

echo "Installing yay AUR manager..."
yay_dir="/home/$username/aur/yay"
arch-chroot "$mount_path" su - "$username" -c "git clone https://aur.archlinux.org/yay-bin.git $yay_dir"
arch-chroot "$mount_path" su - "$username" -c "cd $yay_dir; makepkg -si; yay -Y --gendb; yay -Syu --devel"

echo "Installing additional aur packages..."
arch-chroot "$mount_path" su - "$username" -c "yay -Sy ${aur_packages[*]}"

echo "Add user to groups..."
arch-chroot "$mount_path" usermod -aG "${groups[@]}" "$username"

echo "Enabling start-up services..."
arch-chroot "$mount_path" systemctl enable "${services[@]}"

echo "Recreate the initramfs image..."
arch-chroot "$mount_path" mkinitcpio -P

echo "Installing rEFInd..."
arch-chroot "$mount_path" refind-install --preloader /usr/share/preloader-signed/PreLoader.efi

echo "Configuring rEFInd..."
cp ./refind/refind.conf /mnt/boot/EFI/refind/refind.conf
