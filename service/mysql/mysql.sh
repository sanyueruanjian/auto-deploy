#!/bin/bash
# 错误中断
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

# 第一个容器进行的操作（一般是拷贝 Dockerfile）
#if [ $ID -eq 1 ]; then
#fi

# 以下是每个mysql容器配置文件都会进行的操作
read -p "第 $ID 个 | 请输入与mysql容器 3306 映射的端口(默认 3306): " port

sed -e "s/REPLACE_NAME/${PROJECT_NAME}_mysql_${ID}/g" \
    -e "s/REPLACE_CONTAINER_PATH/${PROJECT_NAME}_mysql_${ID}/g" \
    -e "s/REPLACE_PORT/${port:-3306}/g" \
    $CURRENT_DIR/mysql.yml >> $PROJECT_DIR/docker-compose.yml

echo "${PROJECT_NAME}_mysql_${ID} 配置文件已生成 OK"