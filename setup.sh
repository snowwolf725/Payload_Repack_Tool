#!/bin/bash

# Script Function: Create dynamic_partitions_info.txt and ab_partitions.txt configuration files

CONFIG_FILE="META/dynamic_partitions_info.txt"

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Display colored messages
error_msg() {
    echo -e "${RED}[ERROR] $1${NC}"
}

success_msg() {
    echo -e "${GREEN}[SUCCESS] $1${NC}"
}

info_msg() {
    echo -e "${YELLOW}[INFO] $1${NC}"
}

# Check if input is a valid number
validate_number() {
    local input=$1
    local name=$2
    
    if ! [[ "$input" =~ ^[0-9]+$ ]]; then
        error_msg "$name must be a valid number!"
        return 1
    fi
    
    # Check if it's 0
    if [ "$input" -eq 0 ]; then
        error_msg "$name cannot be 0!"
        return 1
    fi
    
    return 0
}

# Use nameref to pass array references
find_common_elements_nameref() {
    # Declare nameref parameters
    local -n arr1_ref=$1  # Reference to first array
    local -n arr2_ref=$2  # Reference to second array
    local -n result_ref=$3 # Reference to result array
    
    # Clear result array
    result_ref=()
    
    # Double loop comparison
    for item1 in "${arr1_ref[@]}"; do
        for item2 in "${arr2_ref[@]}"; do
            if [[ "$item1" == "$item2" ]]; then
                result_ref+=("$item1")
                break
            fi
        done
    done
}

# Main function
main() {
    # Check if IMAGES directory exists
    if [ ! -d "IMAGES" ]; then
        error_msg "IMAGES directory does not exist!"
        exit 1
    fi
    
    # Clear or create file
    > META/ab_partitions.txt
    
    # Find .img files and process
    declare -a IMAGE_ARRAY=()
    declare -a DYNAMIC_PARTITION_ARRAY=("my_bigball" "my_carrier" "my_company" "my_engineering" "my_heytap" "my_manifest" "my_preload" "my_product" "my_region" "my_stock" "odm" "odm_dlkm" "product" "system" "system_dlkm" "system_ext" "vendor" "vendor_dlkm")
    
    while read -r file; do
        # Get filename (without extension)
        filename=$(basename "$file" .img)
        echo "$filename" >> META/ab_partitions.txt
        IMAGE_ARRAY+=("$filename")
    done < <(find IMAGES -name "*.img" -type f)
    
    # Declare result array
    declare -a common_items

    # Find common partitions
    find_common_elements_nameref IMAGE_ARRAY DYNAMIC_PARTITION_ARRAY common_items

    echo -e "${GREEN}=== Dynamic Partitions Info Configuration Generator ===${NC}"
    echo ""
    
    # Check if config file already exists
    if [ -f "$CONFIG_FILE" ]; then
        info_msg "Found existing configuration file: $CONFIG_FILE"
        read -p "Backup and overwrite? (y/N): " BACKUP_CONFIRM
        
        if [[ "$BACKUP_CONFIRM" =~ ^[Yy]$ ]]; then
            BACKUP_FILE="${CONFIG_FILE}.bak.$(date +%Y%m%d_%H%M%S)"
            cp "$CONFIG_FILE" "$BACKUP_FILE"
            success_msg "Original file backed up to: $BACKUP_FILE"
        else
            error_msg "Operation cancelled."
            exit 1
        fi
    fi
    
    # Get super partition size
    while true; do
        echo ""
        echo "Enter super partition size:"
        echo "Example: 8589934592 (8GB), 17179869184 (16GB)"
        echo "Unit: bytes (1GB = 1073741824 bytes)"
        read -p "super_partition_size[17179869184]: " SUPER_SIZE
        
        if [ -z "$SUPER_SIZE" ]; then
            SUPER_SIZE=17179869184
        fi
        
        if validate_number "$SUPER_SIZE" "super partition size"; then
            # Convert to human readable format
            if [ "$SUPER_SIZE" -ge 1073741824 ]; then
                GB_SIZE=$((SUPER_SIZE / 1073741824))
                info_msg "Super partition size: $GB_SIZE GB"
            elif [ "$SUPER_SIZE" -ge 1048576 ]; then
                MB_SIZE=$((SUPER_SIZE / 1048576))
                info_msg "Super partition size: $MB_SIZE MB"
            fi
            break
        fi
    done
    
    # Get partition group name
    echo ""
    echo "Enter super partition group name:"
    echo "Example: qti_dynamic_partitions, google_dynamic_partitions"
    read -p "super_partition_groups[qti_dynamic_partitions]: " SUPER_GROUPS
    
    if [ -z "$SUPER_GROUPS" ]; then
        SUPER_GROUPS=qti_dynamic_partitions
    fi
    info_msg "Partition group name: $SUPER_GROUPS"
    
    # Get partition group size
    while true; do
        echo ""
        echo "Enter partition group size (should be equal to or slightly less than super partition size):"
        read -p "super_partition_groups_size[17175674880]: " GROUP_SIZE
        
        if [ -z "$GROUP_SIZE" ]; then
            GROUP_SIZE=17175674880
        fi
        
        if validate_number "$GROUP_SIZE" "partition group size"; then
            # Check if it's less than or equal to super partition size
            if [ "$GROUP_SIZE" -gt "$SUPER_SIZE" ]; then
                error_msg "Warning: Partition group size ($GROUP_SIZE) should not be greater than super partition size ($SUPER_SIZE)"
                read -p "Continue? (y/N): " CONTINUE
                if [[ ! "$CONTINUE" =~ ^[Yy]$ ]]; then
                    continue
                fi
            fi
            break
        fi
    done
    info_msg "Partition group size: $GROUP_SIZE"
    
    # Dynamic partition list
    DYNAMIC_PARTITION_LIST="${common_items[*]}"
    echo ""
    echo "Dynamic partition list? (Example: system vendor product odm)"
    read -p "Enter dynamic sub-partitions list in Super partition[$DYNAMIC_PARTITION_LIST]: " PARTITION_LIST
    
    if [ -z "$PARTITION_LIST" ]; then
        PARTITION_LIST="$DYNAMIC_PARTITION_LIST"
    fi
    
        # Create postinstall_config
    read -p "Do you want to create postinstall_config.txt (y/N): " POSTINS_CONFIRM
    
    if [[ "$POSTINS_CONFIRM" =~ ^[Yy]$ ]]; then
        declare -a POSINS_ARRAY=("my_preload" "vendor")
        declare -a pos_items=()
        > META/postinstall_config.txt
        find_common_elements_nameref IMAGE_ARRAY POSINS_ARRAY pos_items
        for item in "${pos_items[@]}"; do
            echo "RUN_POSTINSTALL_$item=true" >> META/postinstall_config.txt
            echo "POSTINSTALL_PATH_$item=bin/checkpoint_gc" >> META/postinstall_config.txt
        done
    else
        rm META/postinstall_config.txt
    fi
    
    # Display configuration summary
    echo ""
    echo -e "${GREEN}=== Configuration Summary ===${NC}"
    echo "Super partition size: $SUPER_SIZE"
    echo "Partition group name: $SUPER_GROUPS"
    echo "Partition group size: $GROUP_SIZE"
    echo "Partition list: $PARTITION_LIST"
    echo ""
    
    # Final confirmation
    read -p "Write to $CONFIG_FILE? (y/N): " FINAL_CONFIRM
    
    if [[ ! "$FINAL_CONFIRM" =~ ^[Yy]$ ]]; then
        error_msg "Operation cancelled."
        exit 0
    fi
    
    # Create configuration file
    cat > "$CONFIG_FILE" << EOF
# Dynamic Partitions Info
# Generated by script on $(date)
# Do not edit manually unless you know what you're doing

virtual_ab=true

# super partition size in bytes
super_partition_size=$SUPER_SIZE

# partition groups
super_partition_groups=$SUPER_GROUPS

# group size
super_${SUPER_GROUPS}_group_size=$GROUP_SIZE
EOF
    
    # Add optional dynamic partition list
    if [ -n "$PARTITION_LIST" ]; then
        cat >> "$CONFIG_FILE" << EOF

# dynamic partition list
super_${SUPER_GROUPS}_partition_list=$PARTITION_LIST
EOF
    fi
    
    # Add helpful comments
    cat >> "$CONFIG_FILE" << EOF

# Additional notes:
# 1. super_partition_size must match the actual size of super partition
# 2. super_partition_groups defines the group name for dynamic partitions
# 3. Group size should be equal to or slightly less than super partition size
# 4. dynamic_partition_list contains all partitions that will be created
EOF
    
    # Check result
    if [ $? -eq 0 ]; then
        success_msg "Configuration file successfully created: $CONFIG_FILE"
        echo ""
        info_msg "File content:"
        echo "========================================="
        cat "$CONFIG_FILE"
        echo "========================================="
        
        # Display file information
        FILE_SIZE=$(wc -c < "$CONFIG_FILE")
        LINE_COUNT=$(wc -l < "$CONFIG_FILE")
        echo ""
        info_msg "File info: $LINE_COUNT lines, $FILE_SIZE bytes"
    else
        error_msg "Failed to create file!"
        exit 1
    fi
}

# Execute main function
main