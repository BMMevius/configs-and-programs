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
        cmd="echo pacstrap $mount_path"
    elif [ "$repo" = "aur" ]; then
        cmd="echo arch-chroot /mnt su - $username -c yay -Sy --needed"
    fi

    while IFS= read -r line; do
        if [ "${line:0:9}" = "packages=" ]; then
            IFS='=' read -r -a packages <<< "$line"
            IFS=' ' read -r -a package_array <<< "${packages[1]}"
            $cmd "${package_array[*]}"
        fi
    done <"$file"
}

parse_config() {
    config_path="./config.conf"
    packages=()
    services=()
    commands=()
    groups=()
    aur_packages=()
    gpu_config_folders=()
    nvidia_packages=(nvidia nvidia-utils nvidia-settings)
    secondary_nvidia_packages=(nvidia-prime)
    nvidia_services=(nvidia-persistenced.service)
    nvidia_configs_folder="./nvidia/**"
    secondary_nvidia_configs_folder="./nvidia-prime/**"
    intel_packages=(mesa lib32-mesa xf86-video-intel vulkan-intel intel-media-driver libva-intel-driver intel-gpu-tools)
    intel_configs_folder="./intel/**"
    amd_packages=(mesa lib32-mesa xf86-video-amdgpu amdvlk lib32-amdvlk libva-mesa-driver lib32-libva-mesa-driver mesa-vdpau lib32-mesa-vdpau radeontop)
    amd_configs_folder="./amd/**"

    prev_section=0
    while IFS= read -r line; do
        case "$line" in
            \[*\])
                # The slicing removes the brackets
                prev_section=${line:1:-1}
            ;;
            packages=*)
                IFS='=' read -r -a split_on_equals <<< "$line"
                IFS=' ' read -r -a list <<< "${split_on_equals[1]}"
                packages+=("${list[@]}")
            ;;
            aur-packages=*)
                IFS='=' read -r -a split_on_equals <<< "$line"
                IFS=' ' read -r -a list <<< "${split_on_equals[1]}"
                aur_packages+=("${list[@]}")
            ;;
            services=*)
                IFS='=' read -r -a split_on_equals <<< "$line"
                IFS=' ' read -r -a list <<< "${split_on_equals[1]}"
                services+=("${list[@]}")
            ;;
            groups=*)
                IFS='=' read -r -a split_on_equals <<< "$line"
                IFS=' ' read -r -a list <<< "${split_on_equals[1]}"
                groups+=("${list[@]}")
            ;;
            command=*)
                IFS='=' read -r -a split_on_equals <<< "$line"
                commands+=("${split_on_equals[1]}")
            ;;
            boot-path=*)
                if [ "$prev_section" = "base" ]; then
                    IFS='=' read -r -a split_on_equals <<< "$line"
                    boot_path=${split_on_equals[1]}
                fi
            ;;
            mount-path=*)
                if [ "$prev_section" = "base" ]; then
                    IFS='=' read -r -a split_on_equals <<< "$line"
                    mount_path=${split_on_equals[1]}
                fi
            ;;
            root-password=*)
                if [ "$prev_section" = "base" ]; then
                    IFS='=' read -r -a split_on_equals <<< "$line"
                    root_password=${split_on_equals[1]}
                fi
            ;;
            username=*)
                if [ "$prev_section" = "base" ]; then
                    IFS='=' read -r -a split_on_equals <<< "$line"
                    username=${split_on_equals[1]}
                fi
            ;;
            password=*)
                if [ "$prev_section" = "base" ]; then
                    IFS='=' read -r -a split_on_equals <<< "$line"
                    password=${split_on_equals[1]}
                fi
            ;;
            primary=*)
                if [ "$prev_section" = "gpu" ]; then
                    IFS='=' read -r -a split_on_equals <<< "$line"
                    primary_gpu=${split_on_equals[1]}
                    case "$primary_gpu" in
                    "nvidia")
                        packages+=("${nvidia_packages[@]}")
                        gpu_config_folders+=("$nvidia_configs_folder")
                    ;;
                    "intel")
                        packages+=("${intel_packages[@]}")
                        gpu_config_folders+=("$intel_configs_folder")
                    ;;
                    "amd")
                        packages+=("${amd_packages[@]}")
                        gpu_config_folders+=("$amd_configs_folder")
                    ;;
                    esac
                fi
            ;;
            secondary=*)
                if [ "$prev_section" = "gpu" ]; then
                    IFS='=' read -r -a split_on_equals <<< "$line"
                    secondary_gpu=${split_on_equals[1]}
                    case "$secondary_gpu" in
                    "nvidia")
                        packages+=("${secondary_nvidia_packages[@]}")
                        services+=("${nvidia_services[@]}")
                        gpu_config_folders+=("$secondary_nvidia_configs_folder" "$nvidia_configs_folder")
                    ;;
                    "intel")
                        gpu_config_folders+=("$intel_configs_folder")
                    ;;
                    "amd")
                        gpu_config_folders+=("$amd_configs_folder")
                    ;;
                    esac
                fi
            ;;
        esac
    done <"$config_path"

    export packages
    export aur_packages
    export services
    export commands
    export mount_path
    export boot_path
    export root_password
    export username
    export password
    export gpu_config_folders
}
