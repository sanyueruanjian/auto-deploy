#!/bin/bash

# 说明：
# 1) 在使用脚本前需要先装 docker 和 docker-compose，最好配置docker镜像加速和阿里yml
# 2) 构建的项目在 target 文件夹下以项目名（PROJECT_NAME）命名，构建完成后可以直接运行

#------ 构建 docker-compose.yml 需填的信息-------------
# 项目名，这是必填项
PROJECT_NAME=liuqichun

# 设置构建容器的数量，如果不构建填：0
mysql=1
nginx=1
nvm=1
redis=1
marchsoft_api=1
rabbitmq=1
portainer=1
#----------------------------------------------------

#--------- 脚本路径环境变量 用户无需更改------------------
PROJECT_DIR="$PWD/target/$PROJECT_NAME"
SERVICE_DIR="$PWD/service"
COMMON_DIR="$PWD/COMMON"
#-----------------------------------------------------

# 将本文件夹下的dos格式文件转换为unix格式文件 #输出重定向到黑洞文件
#dos2unix `find . -type f` 2>/dev/null 1>&2 

# 对文件夹进行处理，如果存在将之前的清空
if [ -e "$PROJECT_DIR" ]; then
    rm -rf $PROJECT_DIR/*
else
    echo "不存在, 创建文件夹"
    mkdir -p $PROJECT_DIR
fi

# 拷贝环境变量到工作区
cp $PWD/common/compose.env  $PROJECT_DIR

# 创建docker-compose文件
if [ ! -e "$PROJECT_DIR/docker-compose.yml" ]; then
    touch $PROJECT_DIR/docker-compose.yml
fi

# 加载 docker-compose的header配置
cat $PWD/common/base/header.yml > $PROJECT_DIR/docker-compose.yml

# 生成 mysql 容器配置
for ((i=1; i<=$mysql; i++)){
    sh $SERVICE_DIR/mysql/mysql.sh $i $SERVICE_DIR/mysql $PROJECT_DIR
}

# 生成 nginx 部分配置
for ((i=1; i<=$nginx; i++)){
    sh $SERVICE_DIR/nginx/nginx.sh $i $SERVICE_DIR/nginx $PROJECT_DIR
}

# 生成 nvm 部分配置
for ((i=1; i<=$nvm; i++)) {
    sh $SERVICE_DIR/nvm/nvm.sh $i $SERVICE_DIR/nvm $PROJECT_DIR
}

# 生成 redis 容器配置
for ((i=1; i<=$redis; i++)){
    sh $SERVICE_DIR/redis/redis.sh $i $SERVICE_DIR/redis $PROJECT_DIR
}

# 生成 后端api 容器配置
for ((i=1; i<=$marchsoft_api; i++)){
    sh $SERVICE_DIR/marchsoft-api/marchsoft-api.sh $i $SERVICE_DIR/marchsoft-api $PROJECT_DIR
}

# 生成 rabbitmq 容器配置
for ((i=1; i<=$rabbitmq; i++)){
    sh $SERVICE_DIR/rabbitmq/rabbitmq.sh $i $SERVICE_DIR/rabbitmq $PROJECT_DIR
}

# 生成 portainer 部分配置
for ((i=1; i<=$portainer; i++)){
    sh $SERVICE_DIR/portainer/portainer.sh $i $SERVICE_DIR/portainer $PROJECT_DIR
}

cat $PWD/common/base/footer.yml >> $PROJECT_DIR/docker-compose.yml

# 创建公共业务网桥
docker network ls | grep "marchsoft_biz_net" 2>/dev/null 1>&2
if [ $? -ne 0 ]; then
    docker network create --driver=bridge --subnet="172.22.0.0/16" --attachable="true" --gateway="172.22.0.1" marchsoft_biz_net
    echo "创建 network: marchsoft_biz_net"
fi

