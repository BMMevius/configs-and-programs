#!/usr/bin/env bash

read -d "\n" -r -a partitions <<< "$(lsblk -l | awk '{if ($6=="part") print $1}')"

select_partition() {
    title=$1

    PS3=$title
    select partition in "${partitions[@]}"
    do
        if [ -n "$partition" ]; then
            break
        fi
    done
    echo "Selected partition: $partition"
    export partition
}

wipe_partition() {
    partition=$1
    type=$2
    fat_args=()
    if [ "$type" == "fat" ]; then
        fat_args=("-F" "32")
    fi

    PS3="Wipe partition? (This will destroy all data contained on that partition!) "
    select answer in "yes" "no"
    do
        umount "/dev/$partition"
        case $answer in
            yes)
                echo "Wiping off data from partition $partition..."
                mkfs -t "$type" "${fat_args[@]}" "/dev/$partition"
                break
                ;;
            no)
                echo "Skipping wipe operation"
                break
                ;;
        esac
    done
}

export mount_path=/mnt
umount "/mnt/boot"
select_partition "Partition to install arch linux on: "
wipe_partition "$partition" ext4
e2label "/dev/$partition" "arch_os"
mount --mkdir "/dev/$partition" "$mount_path"

select_partition "Boot partition: "
wipe_partition "$partition" fat
fatlabel "/dev/$partition" "boot"
mount --mkdir "/dev/$partition" "/mnt/boot"
