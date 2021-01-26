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

# 第一个容器进行的操作（一般是拷贝 Dockerfile）
if [ $ID -eq 1 ]; then
    if [ ! -e "$PROJECT_DIR/redis" ]; then
        mkdir -p "$PROJECT_DIR/redis"
    fi
    cp -rf $CURRENT_DIR/material/* "$PROJECT_DIR/redis"
fi

# 需要替换redis为配置容器名
# 以下是每个容器都会进行的操作， ID表明为第几个容器
read -p "第 $ID 个 | 请输入宿主机与redis容器 6379 端口映射的端口(默认:6379): " port

sed -e "s/REPLACE_NAME/${PROJECT_NAME}_redis_${ID}/g" \
    -e "s/REPLACE_CONTAINER_PATH/${PROJECT_NAME}_redis_${ID}/g" \
    -e "s/REPLACE_PORT/${port:-6379}/g" \
    $CURRENT_DIR/redis.yml >> $PROJECT_DIR/docker-compose.yml

echo "${PROJECT_NAME}_redis_${ID} 配置文件已生成 OK"