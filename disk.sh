#!/usr/bin/env bash

PS3="Partition to install arch linux on: "
read -d "\n" -r -a partitions <<< "$(lsblk -l | awk '{if ($6=="part") print $1}')"

select partition in "${partitions[@]}"
do
    if [ -n "$partition" ]; then
        break
    fi
done
echo "Selected partition: $partition"

PS3="Wipe partition? (This will destroy all data contained on that partition!) "
select answer in "yes" "no"
do
    case $answer in
        yes)
            echo "Wiping off data from partition $partition..."
            umount "$partition"
            mkfs -t ext4 "$partition"
            break
            ;;
        no)
            echo "Skipping wipe operation"
            break
            ;;
    esac
done
export mount_path=/mnt
mount --mkdir "$partition" "$mount_path"
