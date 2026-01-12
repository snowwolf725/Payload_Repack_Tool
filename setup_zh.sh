#!/bin/bash


# 脚本功能: 创建 dynamic_partitions_info.txt 及 ab_partitions.txt 配置文件

CONFIG_FILE="META/dynamic_partitions_info.txt"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 显示带颜色的消息
error_msg() {
    echo -e "${RED}[错误] $1${NC}"
}

success_msg() {
    echo -e "${GREEN}[成功] $1${NC}"
}

info_msg() {
    echo -e "${YELLOW}[信息] $1${NC}"
}

# 检查是否输入了有效的数字
validate_number() {
    local input=$1
    local name=$2
    
    if ! [[ "$input" =~ ^[0-9]+$ ]]; then
        error_msg "$name 必须是有效的数字!"
        return 1
    fi
    
    # 检查是否为 0
    if [ "$input" -eq 0 ]; then
        error_msg "$name 不能为 0!"
        return 1
    fi
    
    return 0
}

# 使用 nameref 传递数组引用
find_common_elements_nameref() {
    # 声明 nameref 参数
    local -n arr1_ref=$1  # 引用第一个数组
    local -n arr2_ref=$2  # 引用第二个数组
    local -n result_ref=$3 # 引用结果数组
    
    # 清空结果数组
    result_ref=()
    
    # 双层循环比较
    for item1 in "${arr1_ref[@]}"; do
        for item2 in "${arr2_ref[@]}"; do
            if [[ "$item1" == "$item2" ]]; then
                result_ref+=("$item1")
                break
            fi
        done
    done
}

# 主函数
main() {
    # 检查 IMAGES 目录是否存在
    if [ ! -d "IMAGES" ]; then
        echo "错误：IMAGES 目录不存在！"
        exit 1
    fi
    # 清空或创建文件
    > META/ab_partitions.txt
    
    # 查找 .img 文件并处理
    declare -a IMAGE_ARRAY=()
    declare -a DYNAMIC_PARTITION_ARRAY=("my_bigball" "my_carrier" "my_company" "my_engineering" "my_heytap" "my_manifest" "my_preload" "my_product" "my_region" "my_stock" "odm" "odm_dlkm" "product" "system" "system_dlkm" "system_ext" "vendor" "vendor_dlkm")
    while read -r file; do
        # 获取文件名（不包括扩展名）
        filename=$(basename "$file" .img)
        echo "$filename" >> META/ab_partitions.txt
        IMAGE_ARRAY+=("$filename")
    done < <(find IMAGES -name "*.img" -type f)
    
    # 声明结果数组
    declare -a common_items

    # 比对共同的分区
    find_common_elements_nameref IMAGE_ARRAY DYNAMIC_PARTITION_ARRAY common_items

    echo -e "${GREEN}=== Dynamic Partitions Info 配置生成工具 ===${NC}"
    echo ""
    
    # 检查是否已有配置文件
    if [ -f "$CONFIG_FILE" ]; then
        info_msg "发现已存在的配置文件: $CONFIG_FILE"
        read -p "是否备份并覆盖? (y/N): " BACKUP_CONFIRM
        
        if [[ "$BACKUP_CONFIRM" =~ ^[Yy]$ ]]; then
            BACKUP_FILE="${CONFIG_FILE}.bak.$(date +%Y%m%d_%H%M%S)"
            cp "$CONFIG_FILE" "$BACKUP_FILE"
            success_msg "原文件已备份到: $BACKUP_FILE"
        else
            error_msg "操作已取消。"
            exit 1
        fi
    fi
    
    # 获取 super 分区大小
    while true; do
        echo ""
        echo "请输入 super 分区大小:"
        echo "示例: 8589934592 (8GB)， 17179869184（16GB)"
        echo "单位: 字节 (1GB = 1073741824 字节)"
        read -p "super_partition_size[17179869184]: " SUPER_SIZE
        
        if [ -z "$SUPER_SIZE" ]; then
            SUPER_SIZE=17179869184
        fi
        
        if validate_number "$SUPER_SIZE" "super 分区大小"; then
            # 转换为人类可读格式
            if [ "$SUPER_SIZE" -ge 1073741824 ]; then
                GB_SIZE=$((SUPER_SIZE / 1073741824))
                info_msg "Super 分区大小: $GB_SIZE GB"
            elif [ "$SUPER_SIZE" -ge 1048576 ]; then
                MB_SIZE=$((SUPER_SIZE / 1048576))
                info_msg "Super 分区大小: $MB_SIZE MB"
            fi
            break
        fi
    done
    
    # 获取分区组名称
    echo ""
    echo "请输入 super 分区组名称:"
    echo "示例: qti_dynamic_partitions, google_dynamic_partitions"
    read -p "super_partition_groups[qti_dynamic_partitions]: " SUPER_GROUPS
    
    if [ -z "$SUPER_GROUPS" ]; then
        SUPER_GROUPS=qti_dynamic_partitions
    fi
    info_msg "分区组名称: $SUPER_GROUPS"
    
    # 获取分区组大小
    while true; do
        echo ""
        echo "请输入分区组大小 (应与 super 分区大小相同或略小):"
        read -p "super_partition_groups_size[17175674880]: " GROUP_SIZE
        
        if [ -z "$GROUP_SIZE" ]; then
            GROUP_SIZE=17175674880
        fi
        
        if validate_number "$GROUP_SIZE" "分区组大小"; then
            # 建议检查是否小于等于 super 分区大小
            if [ "$GROUP_SIZE" -gt "$SUPER_SIZE" ]; then
                error_msg "警告: 分区组大小 ($GROUP_SIZE) 不应大于 super 分区大小 ($SUPER_SIZE)"
                read -p "是否继续? (y/N): " CONTINUE
                if [[ ! "$CONTINUE" =~ ^[Yy]$ ]]; then
                    continue
                fi
            fi
            break
        fi
    done
    info_msg "分区组大小: $GROUP_SIZE"
    
    # 动态分区列表
    DYNAMIC_PARTITION_LIST="${common_items[*]}"
    echo ""
    echo "动态分区列表? (例如: system vendor product odm)"
    read -p "请输入Super分区内的动态子分区列表[$DYNAMIC_PARTITION_LIST]: " PARTITION_LIST
    if [ -z "$PARTITION_LIST" ]; then
        PARTITION_LIST="$DYNAMIC_PARTITION_LIST"
    fi
    
    # 使用 postinstall_config
    read -p "是否需要建立 postinstall_config.txt (y/N): " POSTINS_CONFIRM
    
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
    
    # 显示配置摘要
    echo ""
    echo -e "${GREEN}=== 配置摘要 ===${NC}"
    echo "super 分区大小: $SUPER_SIZE"
    echo "分区组名称: $SUPER_GROUPS"
    echo "分区组大小: $GROUP_SIZE"
    echo "分区列表: $PARTITION_LIST"
    echo ""
    
    # 最终确认
    read -p "是否写入 $CONFIG_FILE? (y/N): " FINAL_CONFIRM
    
    if [[ ! "$FINAL_CONFIRM" =~ ^[Yy]$ ]]; then
        error_msg "操作已取消。"
        exit 0
    fi
    
    # 创建配置文件
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
    
    # 添加可选的动态分区列表
    if [ -n "$PARTITION_LIST" ]; then
        cat >> "$CONFIG_FILE" << EOF

# dynamic partition list
super_${SUPER_GROUPS}_partition_list=$PARTITION_LIST
EOF
    fi
    
    # 添加一些有用的注释
    cat >> "$CONFIG_FILE" << EOF

# Additional notes:
# 1. super_partition_size must match the actual size of super partition
# 2. super_partition_groups defines the group name for dynamic partitions
# 3. Group size should be equal to or slightly less than super partition size
# 4. dynamic_partition_list contains all partitions that will be created
EOF
    
    # 检查结果
    if [ $? -eq 0 ]; then
        success_msg "配置文件已成功创建: $CONFIG_FILE"
        echo ""
        info_msg "文件内容:"
        echo "========================================="
        cat "$CONFIG_FILE"
        echo "========================================="
        
        # 显示文件信息
        FILE_SIZE=$(wc -c < "$CONFIG_FILE")
        LINE_COUNT=$(wc -l < "$CONFIG_FILE")
        echo ""
        info_msg "文件信息: $LINE_COUNT 行, $FILE_SIZE 字节"
    else
        error_msg "文件创建失败!"
        exit 1
    fi
}

# 执行主函数
main