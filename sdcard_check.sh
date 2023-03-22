#!/bin/sh

set -eu

# Get root partition and its device
root_part=$(findmnt / -o source -n)
root_dev=$(lsblk -no pkname $root_part)

# Get SD Card partitions
partitions=$(lsblk -l -n -o NAME,TYPE | grep "^${root_dev}p. part" | awk '{print $1}')

# Find the last partition
last_part=$(echo "$partitions" | tail -n 1)
last_part_num=$(echo $last_part | grep -o -E '[0-9]+$')

# If last partition is root, expand it
if [ "$root_part" = "/dev/$last_part" ]; then
    echo "Expanding root partition..."
    parted /dev/$root_dev resizepart $last_part_num 100%
    resize2fs /dev/$last_part
    echo "Root partition expanded successfully."
    exit 0
fi

# If last partition is not root, create a new partition using the remaining space
echo "Creating a new storage partition..."
parted -a optimal /dev/$root_dev --script mkpart primary ext4 $(($last_part_num+1))
parted /dev/$root_dev print
echo "New storage partition created successfully."

exit 0
