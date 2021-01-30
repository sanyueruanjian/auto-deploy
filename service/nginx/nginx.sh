#!/bin/bash
# 错误中断, 可视化捕捉错误设置 -euxo
set -e

# 公共子脚本环境变量 start------------------------------------------------
# 第几个容器, 从 1 开始
ID=$1
# 当前路径
CURRENT_DIR=$2
# 项目名
PROJECT_NAME=$3
# 生成文件路径（含有项目名称）
PROJECT_DIR=$4
# 对直接执行此脚本的处理，当前工作目录，和项目路径发生变化
if [ $# -eq 0 ]; then
CURRENT_DIR=$PWD
PROJECT_DIR="$PWD/../../target/tem"
    if [ -e $PROJECT_DIR ]; then
        rm -rf $PROJECT_DIR  
    else
        mkdir -p $PROJECT_DIR
    fi
fi

# service文件夹路径
SERVICE_DIR="$CURRENT_DIR/../../service"
# common文件夹路径
COMMON_DIR="$CURRENT_DIR/../../common"
# 公共子脚本环境变量 end------------------------------------------------


# 第一个容器进行的操作（一般是拷贝 Docrkfile）
if [ $ID -eq 1 ]; then
    if [ ! -e "$PROJECT_DIR/nginx" ]; then
        mkdir -p "$PROJECT_DIR/nginx"
    fi
    cp -rf $CURRENT_DIR/material/* "$PROJECT_DIR/nginx"
fi

read -p "第 $ID 个 | 请输入与nginx的 80 映射端口(默认: 80): " port1
read -p "第 $ID 个 | 请再输入与nginx的 443 映射端口(默认: 443): " port2
read -p "第 $ID 个 | 请再输入与nginx映射的一组(默认: 8001-8008): " port_group
# 以下是每个nginx都会进行的操作
sed -e "s/REPLACE_NAME/${PROJECT_NAME}_nginx_${ID}/g" \
    -e "s/REPLACE_CONTAINER_PATH/${PROJECT_NAME}_nginx_${ID}/g" \
    -e "s/REPLACE_PORT1/${port1:-80}/g" \
    -e "s/REPLACE_PORT2/${port2:-443}/g" \
    -e "s/REPLACE_PORT_GROUP/${port_group:-8001-8008}/g" \
    $CURRENT_DIR/nginx.yml >> $PROJECT_DIR/docker-compose.yml

echo "${PROJECT_NAME}_nginx_${ID} 配置文件已生成 OK"