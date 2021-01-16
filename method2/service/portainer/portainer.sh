#!/bin/bash
# 错误中断
set -e

# 公共子脚本环境变量 start------------------------------------------------
# 第几个容器, 从 1 开始
ID=$1
# 当前路径
CURRENT_DIR=$2
# 生成文件路径（含有项目名称）
PROJECT_DIR=$3
# 这是全局部署路径，通常 GLOBAL_PATH=/root
GLOBAL_PATH=`awk -F "=" '/GLOBAL_PATH/{print $2}' $PROJECT_DIR/compose.env`

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

# 第一个容器进行的操作（config、data...）, 不能为空
#if [ $ID -eq 1 ]; then
#fi

# 以下是每个nginx都会进行的操作
read -p "请输入portainer容器名($ID): " name
read -p "请输入与 9000 映射的端口($ID): " port

sed -e "s/REPLACE_NAME/${name}/g" -e "s/REPLACE_PORT/${port:-9000}/g" $CURRENT_DIR/portainer.yml >> $PROJECT_DIR/docker-compose.yml

echo "$name service 配置文件已生成 OK"