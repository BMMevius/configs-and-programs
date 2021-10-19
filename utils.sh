#!/usr/bin/env bash

set -e

prompt_choice() {
    local message choices
    message=$1
    choices=("${@:2}")

    while true; do
        read -r -p "$message [${choices[*]}]: " REPLY
        for choice in "${choices[@]}"; do
            if [ "${choice,,}" == "${REPLY,,}" ]; then
                echo "$choice"
                return 0
            fi
        done
    done
}

prompt_custom_choice() {
    local message cmd
    message=$1
    cmd=$2

    while true; do
        read -r -p "$message or [S]top: " REPLY
        if [ "s" == "${REPLY,,}" ]; then
            return 0
        else
            bash -c "$(printf "\n$cmd\n" $REPLY)" || echo "Wrong choice..."
        fi
    done
}

install_packages_from_file() {
    local repo file mount_path username cmd
    repo=$1
    file=$2
    mount_path=$3
    username=$4

    if [ "$repo" = "pacman" ]; then
        cmd="pacstrap $mount_path"
    elif [ "$repo" = "aur" ]; then
        cmd="arch-chroot /mnt su - $username -c yay -Sy --needed"
    fi

    while IFS= read -r line; do
        if [ "${line:0:9}" = "packages=" ]; then
            $cmd "${line:9}"
        fi
    done <"$file"
}
