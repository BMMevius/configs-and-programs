#!/usr/bin/env bash

source utils.sh

if [ "$(prompt_choice "Connect to wifi?" "y" "n")" = "y" ]; then
    read -rp "SSID: " ssid
    read -rp "Passphrase: " passphrase
    iwctl --passphrase "$passphrase" station wlan0 connect "$ssid"
    # IP-address is from Google
    while true; do ping -c 1 142.250.179.206 && break; done
fi

if [ "$(prompt_choice "Format disks? (does unmount, format, and remount)" "y" "n")" = "y" ]; then
    fdisk -l
    prompt_custom_choice "Format <disk> <type> <mount path>" 'export disk=%s; umount $disk; mkfs -t %s $disk; export mount_path=%s; mkdir -p $mount_path; mount $disk $mount_path'
elif [ "$(prompt_choice "Mount disks?" "y" "n")" == "y" ]; then
    prompt_custom_choice "Mount <disk> <mount path>" 'export disk=%s; export mount_path=%s; mkdir -p $mount_path; mount $disk $mount_path'
fi

cp ./base/etc/pacman.conf /etc/pacman.conf

echo "Ensure the system clock is accurate..."
timedatectl set-ntp true

read -rp "Mount path of OS install partition: " mount_path
read -rp "Mount path of OS boot partition: " boot_path

echo "Install basic packages..."
pacstrap "$mount_path" base linux linux-firmware git sudo man grub efibootmgr nano vi udisks2 udevil dhcpcd networkmanager
arch-chroot "$mount_path" systemctl enable dhcpcd.service
arch-chroot "$mount_path" systemctl enable NetworkManager.service
arch-chroot "$mount_path" systemctl enable systemd-networkd.service
arch-chroot "$mount_path" systemctl enable systemd-resolved.service

echo "Creating user..."
read -rp "Username: " username
arch-chroot "$mount_path" useradd -mG "$username"
echo "Give new password for login '$username'..."
arch-chroot "$mount_path" passwd "$username"
echo "$username ALL=(ALL) ALL" >>"$mount_path/etc/sudoers"
echo "$username ALL= NOPASSWD: /usr/bin/pacman" >>"$mount_path/etc/sudoers"

echo "Enabling auto USB mounter service..."
arch-chroot "$mount_path" systemctl enable devmon@$username.service

echo "Installing yay AUR manager..."
yay_dir="/home/$username/aur/yay"
arch-chroot "$mount_path" su - "$username" -c "git clone https://aur.archlinux.org/yay-bin.git $yay_dir"
arch-chroot "$mount_path" su - "$username" -c "cd $yay_dir; makepkg -si; yay -Y --gendb; yay -Syu --devel"

echo "Installing additional firmware..."
arch-chroot "$mount_path" su - "$username" -c "yay -Sy aic94xx-firmware wd719x-firmware upd72020x-fw"

echo "Installing xorg server..."
pacstrap "$mount_path" xorg-server

has_laptop=$(prompt_choice "Do you have a laptop?" "y" "n")
has_bluetooth=$(prompt_choice "Do you have bluetooth?" "y" "n")
has_wifi=$has_laptop
[ "$has_laptop" = "n" ] && has_wifi=$(prompt_choice "Do you have a WiFi card?" "y" "n")
desktop_env=$(prompt_choice "Choose a desktop enviroment" "i3" "Xfce")

if [ "$has_wifi" = "y" ]; then
    pacstrap "$mount_path" iw iwd
    arch-chroot "$mount_path" systemctl enable iwd.service
fi

if [ "$has_bluetooth" = "y" ]; then
    pacstrap "$mount_path" bluez
fi

if [ "${desktop_env,,}" = "i3" ]; then
    pacstrap "$mount_path" i3-wm
elif [ "${desktop_env,,}" = "xfce" ]; then
    pacstrap "$mount_path" xfce4 xfwm4 xfwm4-themes xfce4-pulseaudio-plugin xfce4-wavelan-plugin xfce4-clipman-plugin
    [ "$has_laptop" = "y" ] && pacstrap "$mount_path" xfce4-battery-plugin
    [ "$has_wifi" = "y" ] && pacstrap "$mount_path" xfce4-wavelan-plugin
fi

if [ "$(prompt_choice "Install drivers for video card?" "y" "n")" = "y" ]; then
    video_card1=$(prompt_choice "Manufacturer of the primary video card? (connected to display)" "NVIDIA" "Intel" "AMD")
    video_card2=$(prompt_choice "Manufacturer of the secondary video card?" "NVIDIA" "Intel" "AMD" "NONE")
    if [ "${video_card1,,}" = "nvidia" ] || [ "${video_card2,,}" = "nvidia" ]; then
        pacstrap "$mount_path" nvidia nvidia-utils nvidia-settings
        arch-chroot "$mount_path" systemctl enable nvidia-persistenced.service
        cp -rf ./nvidia/** "$mount_path"
        if [ "${video_card2,,}" = "nvidia" ]; then
            pacstrap "$mount_path" nvidia-prime
            cp -rf ./nvidia-prime/** "$mount_path"
            rm "$mount_path/etc/X11/xorg.conf.d/20-nvidia.conf"
        fi
    fi
    if [ "${video_card1,,}" = "intel" ]; then
        pacstrap "$mount_path" mesa lib32-mesa xf86-video-intel vulkan-intel intel-media-driver libva-intel-driver intel-gpu-tools
        cp -rf ./intel/** "$mount_path"
    fi
    if [ "${video_card1,,}" = "amd" ] || [ "${video_card2,,}" = "amd" ]; then
        pacstrap "$mount_path" mesa lib32-mesa xf86-video-amdgpu amdvlk lib32-amdvlk libva-mesa-driver lib32-libva-mesa-driver mesa-vdpau lib32-mesa-vdpau radeontop
        cp -rf ./amd/** "$mount_path"
        if [ "${video_card2,,}" = "amd" ]; then
            rm "$mount_path/etc/X11/xorg.conf.d/20-amdgpu.conf"
        fi
    fi
fi

if [ "$(prompt_choice "Do you want to play games via steam?" "y" "n")" = "y" ]; then
    pacstrap "$mount_path" steam
fi

if [ "$(prompt_choice "Do you want to play games using wine/lutris?" "y" "n")" = "y" ]; then
    pacstrap "$mount_path" lutris wine-staging giflib lib32-giflib libpng lib32-libpng libldap lib32-libldap gnutls lib32-gnutls \
        mpg123 lib32-mpg123 openal lib32-openal v4l-utils lib32-v4l-utils libpulse lib32-libpulse libgpg-error \
        lib32-libgpg-error alsa-plugins lib32-alsa-plugins alsa-lib lib32-alsa-lib libjpeg-turbo lib32-libjpeg-turbo \
        sqlite lib32-sqlite libxcomposite lib32-libxcomposite libxinerama lib32-libgcrypt libgcrypt lib32-libxinerama \
        ncurses lib32-ncurses opencl-icd-loader lib32-opencl-icd-loader libxslt lib32-libxslt libva lib32-libva gtk3 \
        lib32-gtk3 gst-plugins-base-libs lib32-gst-plugins-base-libs vulkan-icd-loader lib32-vulkan-icd-loader
fi

if [ "$(prompt_choice "Install personal packages?" "y" "n")" = "y" ]; then
    install_packages_from_file "pacman" "personal-pacman-packages.conf" "$mount_path" "$username"
    install_packages_from_file "aur" "personal-aur-packages.conf" "$mount_path" "$username"
fi

if [ "$(prompt_choice "Install work tools?" "y" "n")" = "y" ]; then
    pacstrap "$mount_path" docker docker-compose cuda cuda-tools aws-cli openvpn qtcreator qt6 networkmanager-openvpn
    arch-chroot "$mount_path" su - "$username" -c "yay -Syu nvidia-container-toolkit heroku-cli-bin nvm balena-cli-bin"
    arch-chroot "$mount_path" systemctl enable docker.service
    arch-chroot "$mount_path" usermod -aG docker "$username"
fi

prompt_custom_choice "Install terminal environment <package to be installed>" "echo pacstrap $mount_path %s"

echo "Change default shell to zsh..."
arch-chroot /mnt su - "$username" -c "sudo -S chsh -s $(which zsh)"
arch-chroot /mnt su - "$username" -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
arch-chroot /mnt su - "$username" -c 'git clone https://github.com/zdharma/history-search-multi-word.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"/plugins/history-search-multi-word'
arch-chroot /mnt su - "$username" -c 'git clone https://github.com/zsh-users/zsh-autosuggestions.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"/plugins/zsh-autosuggestions'
arch-chroot /mnt su - "$username" -c 'git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"/plugins/zsh-syntax-highlighting'

cp -rf ./user/** "$mount_path/home/$username"
echo "source /usr/share/nvm/init-nvm.sh" >>"/mnt/home/$username/.zshrc"

echo "Generate an fstab file..."
genfstab -L "$mount_path" >>"$mount_path/etc/fstab"

echo "Setting time zone..."
arch-chroot "$mount_path" ln -sf /usr/share/zoneinfo/Europe/Amsterdam /etc/localtime

echo "Generate /etc/adjtime..."
arch-chroot "$mount_path" hwclock --systohc

cp -rf ./base/** "$mount_path"

echo "Generate the locales..."
arch-chroot "$mount_path" locale-gen

echo "Recreate the initramfs image..."
arch-chroot "$mount_path" mkinitcpio -P

echo "Set the root passwd..."
arch-chroot "$mount_path" passwd

echo "Installing grub..."
arch-chroot "$mount_path" grub-install --target=x86_64-efi --efi-directory="${boot_path:4}" --bootloader-id=GRUB
arch-chroot "$mount_path" grub-mkconfig -o "${boot_path:4}/grub/grub.cfg"
