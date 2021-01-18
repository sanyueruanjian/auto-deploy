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
#if [ $ID -eq 1 ]; then
#fi

# 需要替换xxx为配置容器名, 所有需要sed替换的以 REPLACE_ 开头
# 以下是每个容器都会进行的操作， ID表明为第几个容器
# 使用 sed 命令后端的 \ (转义) 后面不能有空格

sed -e "s/REPLACE_NAME/${PROJECT_NAME}_xxx_${ID}/g" \
    $CURRENT_DIR/xxx.yml >> $PROJECT_DIR/docker-compose.yml

echo "${PROJECT_NAME}_xxx_${ID} 配置文件已生成 OK"