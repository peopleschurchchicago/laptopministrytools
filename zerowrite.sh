#!/bin/bash
# A BASH script written for zero-write storage devices whether they are HDD or SSD type. Included for the Laptop Ministry work.

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root."
    exit 1
fi

# Function to check and install required tools
install_dependencies() {
    command -v smartctl >/dev/null 2>&1 || apt-get install -y smartmontools
    command -v memtester >/dev/null 2>&1 || apt-get install -y memtester
}

# Identify the main storage drive
identify_drive() {
    main_drive=$(lsblk -ndo NAME,TYPE | grep -E 'disk$' | awk '{print $1}' | head -n1)
    echo "/dev/$main_drive"
}

# Determine drive type (SSD or HDD)
determine_drive_type() {
    local drive=$1
    if smartctl -i "$drive" | grep -iq "Solid State"; then
        echo "SSD"
    else
        echo "HDD"
    fi
}

# Zero-write the drive
zero_write_drive() {
    local drive=$1
    local type=$2

    echo "Zero-writing $drive ($type)..."
    if [[ "$type" == "SSD" ]]; then
        # Use `blkdiscard` for SSDs
        blkdiscard "$drive" && echo "Secure erase completed for SSD." || echo "Failed to secure erase SSD."
    elif [[ "$type" == "HDD" ]]; then
        # Use `dd` for HDDs
        dd if=/dev/zero of="$drive" bs=1M status=progress && sync
        echo "Zero-write completed for HDD."
    fi
}

# Test memory
test_memory() {
    echo "Testing memory with memtester (512MB)..."
    memtester 512M 1
}

# Test disk health
test_disk_health() {
    local drive=$1
    echo "Checking disk health for $drive..."
    smartctl -H "$drive"
    echo "Running SMART extended self-test (this may take time)..."
    smartctl -t long "$drive"
}

# Main execution
main() {
    install_dependencies
    drive=$(identify_drive)

    if [[ -z "$drive" ]]; then
        echo "No storage drive detected."
        exit 1
    fi

    drive_type=$(determine_drive_type "$drive")
    echo "Main storage drive: $drive ($drive_type)"

    zero_write_drive "$drive" "$drive_type"
    test_memory
    test_disk_health "$drive"
}

main
