#!/usr/bin/env bash

read -d "\n" -r -a partitions <<< "$(lsblk -l | awk '{if ($6=="part") print $1}')"
read -d "\n" -r -a disks <<< "$(lsblk -l | awk '{if ($6=="disk") print $1}')"

select_list() {
    read -r -a items <<< "$1"
    title=$2

    PS3=$title
    select item in "${items[@]}"
    do
        if [ -n "$item" ]; then
            break
        fi
    done
    export item
}

select_partition() {
    title=$1

    select_list "${partitions[*]}" "$title"
    echo "Selected partition: $partition"
    export partition="/dev/$item"
}

select_disk() {
    title=$1

    select_list "${disks[*]}" "$title"
    echo "Selected disk: $disk"
    export disk="/dev/$item"
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
        umount "$partition"
        case $answer in
            yes)
                echo "Wiping off data from partition $partition..."
                mkfs -t "$type" "${fat_args[@]}" "$partition"
                break
                ;;
            no)
                echo "Skipping wipe operation"
                break
                ;;
        esac
    done
}

automatic_disk_partitioning() {
    PS3="Do you want to do automatic disk partitioning?
This will create a boot partition and a partition for the OS.
(This will destroy all data contained on that disk!) "
    select answer in "yes" "no"
    do
        case $answer in
            yes)
                select_disk "Disk to automatically partition: "
                echo "Repartitioning disk $disk..."
                umount "$disk"
                sfdisk --delete "$disk"
                sfdisk "$disk" <<EOF
0,2048
;
EOF
                sfdisk --change-id "$disk" 1 C12A7328-F81F-11D2-BA4B-00A0C93EC93B
                break
                ;;
            no)
                echo "Skipping automatically partition"
                break
                ;;
        esac
    done
}

automatic_disk_partitioning

export mount_path=/mnt
umount "/mnt/boot"
select_partition "Partition to install arch linux on: "
wipe_partition "$partition" ext4
e2label "$partition" "arch_os"
mount --mkdir "$partition" "$mount_path"

select_partition "Boot partition: "
wipe_partition "$partition" fat
fatlabel "$partition" "boot"
mount --mkdir "$partition" "/mnt/boot"
