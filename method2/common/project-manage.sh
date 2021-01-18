#!/bin/bash
#----------- 项目信息--------------------------------
# 项目名
PROJECT_NAME=deploy
# 构建过程中各个容器的数量
mysql=0
nginx=0
# node 版本管理工具
nvm=0
redis=0
# 后端API容器
marchsoft_api=0
# 消息队列
rabbitmq=0
# docker可视化管理工具
portainer=0
#----------------------------------------------------

#---------- 此脚本环境变量 ----------------------------
GLOBAL_PATH=`awk -F "=" '/GLOBAL_PATH/{print $2}' .env`
#---------------------------------------------------- 


# 每个容器构建前需做的准备
prepare(){
    # 如果docker-compose不存在，则进行下载
    if [ ! -e "/usr/local/bin/docker-compose" ]; then
        echo "未安装docker-compose，正在进行安装..."
        curl -o /usr/local/bin/docker-compose  http://elltor-blog.oss-cn-hangzhou.aliyuncs.com/software/docker-compose
        chmod +x /usr/local/bin/docker-compose
        echo "docker-compose 安装完成"
    fi    
    
    # 创建公共业务网桥
    docker network ls | grep "marchsoft_biz_net" 2>/dev/null 1>&2
    if [ $? -ne 0 ]; then
        docker network create --driver=bridge --subnet="172.22.0.0/16" --attachable="true" --gateway="172.22.0.1" marchsoft_biz_net
        echo "未发现公共网桥，创建 network: marchsoft_biz_net"
    fi
    
    # mysql 容器配置
    #for ((i=1; i<=$mysql; i++)){
    #}
    # nginx 容器配置

    for ((i=1; i<=$nginx; i++)){
        if [ ! -e "$GLOBAL_PATH/${PROJECT_NAME}_nginx_${i}" ]; then
            mkdir -p "$GLOBAL_PATH/${PROJECT_NAME}_nginx_${i}"
        fi
        cp -rf $PWD/nginx/* "$GLOBAL_PATH/${PROJECT_NAME}_nginx_${i}"
    }
    
    # nvm 容器配置
    #for ((i=1; i<=$nvm; i++)) {
    #}
    
    # redis 容器配置
    for ((i=1; i<=$redis; i++)){
        if [ ! -e "$GLOBAL_PATH/${PROJECT_NAME}_redis_${i}" ]; then
            mkdir -p "$GLOBAL_PATH/${PROJECT_NAME}_redis_${i}"
        fi
        cp -rf $PWD/redis/* "$GLOBAL_PATH/${PROJECT_NAME}_redis_${i}"
    }
    
    # 后端api 容器配置
    #for ((i=1; i<=$marchsoft_api; i++)){
    #}

    # rabbitmq 容器配置
    #for ((i=1; i<=$rabbitmq; i++)){
    #}
    
    # portainer 部分配置
    #for ((i=1; i<=$portainer; i++)){ 
    #}      
}

up(){
    docker-compose up -d
}

prepare

up

echo "${PROJECT_NAME}.sh 启动脚本执行完成"