#!/usr/bin/env bash

set -e

prompt_confirm() {
    while true; do
        read -r -n 1 -p "${1:-Continue?} [y/n]: " REPLY
        case $REPLY in
        [yY])
            echo
            return 1
            ;;
        [nN])
            echo
            return 0
            ;;
        *) printf " \033[31m %s \n\033[0m" "invalid input" ;;
        esac
    done
}

if ! prompt_confirm "Connect to wifi?"; then
    read -rp "SSID: " ssid
    iwctl station wlan0 connect "$ssid"
    ping -c 1 google.com
fi

new_pacman_file=/etc/pacman-custom.conf
echo "Creating $new_pacman_file..."
prev_section=0
while IFS= read -r line; do
    if [ "$line" = "#[multilib]" ]; then
        echo "[multilib]" >>$new_pacman_file
        prev_section="[multilib]"
    elif [ "$line" = "#Include = /etc/pacman.d/mirrorlist" ] && [ "$prev_section" = "[multilib]" ]; then
        echo "Include = /etc/pacman.d/mirrorlist" >>$new_pacman_file
    else
        echo "$line" >>$new_pacman_file
    fi
done <"/etc/pacman.conf"
echo "Move custom file to used pacman file..."
mv $new_pacman_file /etc/pacman.conf

timedatectl set-ntp true

echo "Install packages on new system..."
pacstrap /mnt base linux linux-firmware linux-headers \
    iwd iw lutris steam sudo docker docker-compose nvidia cuda cuda-tools xf86-video-intel mesa zsh man aws-cli \
    openvpn git qtcreator qt6 base-devel dlang firefox networkmanager-openvpn grub efibootmgr nano vi vifm \
    wine-staging giflib lib32-giflib libpng lib32-libpng libldap lib32-libldap gnutls lib32-gnutls \
    mpg123 lib32-mpg123 openal lib32-openal v4l-utils lib32-v4l-utils libpulse lib32-libpulse libgpg-error \
    lib32-libgpg-error alsa-plugins lib32-alsa-plugins alsa-lib lib32-alsa-lib libjpeg-turbo lib32-libjpeg-turbo \
    sqlite lib32-sqlite libxcomposite lib32-libxcomposite libxinerama lib32-libgcrypt libgcrypt lib32-libxinerama \
    ncurses lib32-ncurses opencl-icd-loader lib32-opencl-icd-loader libxslt lib32-libxslt libva lib32-libva gtk3 \
    lib32-gtk3 gst-plugins-base-libs lib32-gst-plugins-base-libs vulkan-icd-loader lib32-vulkan-icd-loader wine-mono \
    wayland xorg-xwayland plasma plasma-wayland-session egl-wayland ttf-liberation wqy-zenhei lib32-systemd

genfstab -U /mnt >>/mnt/etc/fstab
arch-chroot /mnt ln -sf /usr/share/zoneinfo/Europe/Amsterdam /etc/localtime
arch-chroot /mnt hwclock --systohc
echo "en_US.UTF-8 UTF-8" >/mnt/etc/locale.gen
arch-chroot /mnt locale-gen
echo "LANG=en_US.UTF-8" >/mnt/etc/locale.conf
echo "laptop-uni" >/mnt/etc/hostname
printf "127.0.0.1	localhost\n::1		localhost\n127.0.1.1	laptop-uni" >/mnt/etc/hosts

new_mkinitcpio_conf="/mnt/etc/mkinitcpio-custom.conf"
echo "Add NVIDIA modules to /etc/mkinitcpio.conf..."
while IFS= read -r line; do
    if [ "$line" = "MODULES=()" ]; then
        echo "MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)" >>$new_mkinitcpio_conf
    else
        echo "$line" >>$new_mkinitcpio_conf
    fi
done <"/mnt/etc/mkinitcpio.conf"
mv $new_mkinitcpio_conf /mnt/etc/mkinitcpio.conf

arch-chroot /mnt mkinitcpio -P
arch-chroot /mnt passwd

echo "Installing GRUB..."
arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB

new_grub_conf="/mnt/etc/default/grub-custom.conf"
echo "Set kernel parameters in /etc/default/grub..."
while IFS= read -r line; do
    if [ "$line" = 'GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet"' ]; then
        echo 'GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet nvidia-drm.modeset=1 systemd.unified_cgroup_hierarchy=false"' >>$new_grub_conf
    else
        echo "$line" >>$new_grub_conf
    fi
done <"/mnt/etc/default/grub"
mv $new_grub_conf /mnt/etc/default/grub
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

echo "NVIDIA NVENC hardware encoding..."
echo 'ACTION=="add", DEVPATH=="/bus/pci/drivers/nvidia", RUN+="/usr/bin/nvidia-modprobe -c0 -u"' >/mnt/etc/udev/rules.d/70-nvidia.rules

echo "Creating pacman hook..."
mkdir -p /mnt/etc/pacman.d/hooks
echo "[Trigger]
Operation=Install
Operation=Upgrade
Operation=Remove
Type=Package
Target=nvidia
Target=linux
# Change the linux part above and in the Exec line if a different kernel is used

[Action]
Description=Update Nvidia module in initcpio
Depends=mkinitcpio
When=PostTransaction
NeedsTargets
Exec=/bin/sh -c 'while read -r trg; do case $trg in linux) exit 0; esac; done; /usr/bin/mkinitcpio -P'
" >/mnt/etc/pacman.d/hooks/nvidia.hook

new_pacman_file=/mnt/etc/pacman-custom.conf
echo "Creating $new_pacman_file..."
prev_section=0
while IFS= read -r line; do
    if [ "$line" = "#[multilib]" ]; then
        echo "[multilib]" >>$new_pacman_file
        prev_section="[multilib]"
    elif [ "$line" = "#Include = /etc/pacman.d/mirrorlist" ] && [ "$prev_section" = "[multilib]" ]; then
        echo "Include = /etc/pacman.d/mirrorlist" >>$new_pacman_file
    else
        echo "$line" >>$new_pacman_file
    fi
done <"/mnt/etc/pacman.conf"
echo "Move custom file to used pacman file..."
mv $new_pacman_file /mnt/etc/pacman.conf

echo "Creating user..."
read -rp "Username:" REPLY
username=$REPLY
arch-chroot /mnt useradd -mG docker "$username"
echo "Give new password for login '$username'..."
arch-chroot /mnt passwd "$username"
echo "bastiaan ALL=(ALL) ALL" >>/mnt/etc/sudoers
echo "$username laptop-uni= NOPASSWD: /usr/bin/pacman -Syu" >>/mnt/etc/sudoers

echo "Copying .zshrc"
cp ".zshrc" "/mnt/home/$username/"

echo "Change default shell to zsh..."
arch-chroot /mnt su - "$username" -c "sudo -S chsh -s $(which zsh)"
arch-chroot /mnt su - "$username" -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
arch-chroot /mnt su - "$username" -c 'git clone https://github.com/zdharma/history-search-multi-word.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"/plugins/history-search-multi-word'
arch-chroot /mnt su - "$username" -c 'git clone https://github.com/zsh-users/zsh-autosuggestions.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"/plugins/zsh-autosuggestions'
arch-chroot /mnt su - "$username" -c 'git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"/plugins/zsh-syntax-highlighting'

# Install yay
yay_dir="/home/$username/aur/yay"
arch-chroot /mnt su - "$username" -c "git clone https://aur.archlinux.org/yay-bin.git $yay_dir"
arch-chroot /mnt su - "$username" -c "cd $yay_dir; makepkg -si"
arch-chroot /mnt su - "$username" -c "yay -Y --gendb"
arch-chroot /mnt su - "$username" -c "yay -Syu --devel"

echo "Adding AUR packages..."
arch-chroot /mnt su - "$username" -c "yay -Syu nvidia-container-toolkit slack-desktop teams onedrive-abraunegg heroku-cli nvm balena-cli-bin aic94xx-firmware wd719x-firmware upd72020x-fw"

new_nvidia_container_toolkit_conf="/mnt/etc/nvidia-container-toolkit/config-custom.toml"
echo "Set parameters in /etc/nvidia-container-toolkit/config.toml..."
while IFS= read -r line; do
    if [ "$line" = "no-cgroups = true" ]; then
        echo "no-cgroups = false" >>$new_nvidia_container_toolkit_conf
    else
        echo "$line" >>$new_nvidia_container_toolkit_conf
    fi
done <"/mnt/etc/nvidia-container-toolkit/config.toml"
mv $new_nvidia_container_toolkit_conf /mnt/etc/nvidia-container-toolkit/config.toml

echo "Enable start-up services..."
arch-chroot /mnt su - "$username" -c "sudo systemctl enable NetworkManager.service"
arch-chroot /mnt su - "$username" -c "sudo systemctl enable networkd.service"
arch-chroot /mnt su - "$username" -c "sudo systemctl enable resolved.service"
arch-chroot /mnt su - "$username" -c "sudo systemctl enable iwd.service"
arch-chroot /mnt su - "$username" -c "sudo systemctl enable docker.service"

arch-chroot /mnt mkinitcpio -P
