#!/bin/bash
# 目前脚本存在问题无法使用 -- 2021/2/1 by liuqichun
PROJECT_NAME=$1
BUILD_PROJECT_DIR=`find /project -type d -name $PROJECT_NAME`
echo "BUILD_PROJECT_DIR: $BUILD_PROJECT_DIR"
NODE_DIR="/root/.nvm/versions/node"
#/root/.nvm/versions/node

# 使用说明
usage(){
    echo "usage"
}

is_node_install(){
    NODE_VERSION=`ls $NODE_DIR | awk 'NR==1'`
    if [ -z $NODE_VERSION ]; then
        echo "请进入 nvm 容器安装一个 node，命令： nvm install --lts"
        return 1
    else
        echo "NODE_VERSION:$NODE_VERSION"
        return 0
    fi
}

case $2 in
    usage)
        usage
    ;;
    npm)
        is_node_install
        if [ $? -eq 0 ]; then
            cd $BUILD_PROJECT_DIR
            pwd
            echo "npm path:  $NODE_DIR/$NODE_VERSION/bin/npm"
            exec $NODE_DIR/$NODE_VERSION/bin/npm $3 $4 $5 $6 $7
        else
            exit 1
        fi
    ;;
    *)
        usage
    ;;
esac
