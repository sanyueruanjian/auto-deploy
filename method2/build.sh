#!/bin/bash

# 说明：
# 1) 在使用脚本前需要先装 docker 和 docker-compose，最好配置docker镜像加速和阿里yml
# 2) 构建的项目在 target 文件夹下以项目名（PROJECT_NAME）命名，构建完成后可以直接运行
# 3) 如果脚本中存在 '\r' 回车符原因不能执行，这里推荐下载 dos2unix 把当前下所有文件格式化为unix格式文件，
#    下载完软件后在下方取消注释可以对当前目录下的所有文件进行转换，

#------ 构建 docker-compose.yml 需填的信息-------------
# 项目名，这是必填项
PROJECT_NAME=my_project_name

# 设置构建容器的数量, 值为非负数, 如果不构建填：0
mysql=0
nginx=0
nvm=0
redis=0
marchsoft_api=0
rabbitmq=0
portainer=0
#----------------------------------------------------


#--------- 脚本路径环境变量 用户无需更改------------------
PROJECT_DIR="$PWD/target/$PROJECT_NAME"
SERVICE_DIR="$PWD/service"
COMMON_DIR="$PWD/COMMON"

#-----------------------------------------------------


# ----- 操作前准备工作，格式转换、软件安装、创建目录... ------
# 文件格式转换，将本文件夹下的dos格式文件转换为unix格式文件 #输出重定向到黑洞文件
dos2unix `find . -type f` 2>/dev/null 1>&2 

# 对文件夹进行处理，如果存在将之前的清空
if [ -e "$PROJECT_DIR" ]; then
    read -p "在'./target'下已存在项目$PROJECT_NAME，是否清空[y/n]: " res
    if [ $res = "y" ]; then
        rm -rf $PROJECT_DIR/*
        echo "已清空项目 $PROJECT_NAME (.target/$PROJECT_NAME)"
    elif [ $res = "n" ]; then
        echo "项目 $PROJECT_NAME 未清除(./target/$PROJECT_NAME), 运行时请确认一遍配置文件"
    else
        echo "项目 $PROJECT_NAME 未清除(./target/$PROJECT_NAME), 运行时请确认一遍配置文件"
    fi
else
    echo "不存在, 创建文件夹"
    mkdir -p $PROJECT_DIR
fi
#---------------------------------------------------------------------------------------

# 拷贝环境变量到工作区
cat $PWD/common/docker-compose.env > $PROJECT_DIR/.env
cat $PWD/common/project-manage.sh > "$PROJECT_DIR/${PROJECT_NAME}.sh"
chmod +x "$PROJECT_DIR/${PROJECT_NAME}.sh"
# 修改启动项目shell脚本里的项目名
sed -i "s/PROJECT_NAME=.*/PROJECT_NAME=${PROJECT_NAME}/g" "$PROJECT_DIR/${PROJECT_NAME}.sh"
# 修改启动项目shell脚本里的各个容器数量
sed -i "s/mysql=[0-9]*/mysql=${mysql}/g" "$PROJECT_DIR/${PROJECT_NAME}.sh"
sed -i "s/nginx=[0-9]*/nginx=${nginx}/g" "$PROJECT_DIR/${PROJECT_NAME}.sh"
sed -i "s/nvm=[0-9]*/nvm=${nvm}/g" "$PROJECT_DIR/${PROJECT_NAME}.sh"
sed -i "s/redis=[0-9]*/redis=${redis}/g" "$PROJECT_DIR/${PROJECT_NAME}.sh"
sed -i "s/marchsoft_api=[0-9]*/marchsoft_api=${marchsoft_api}/g" "$PROJECT_DIR/${PROJECT_NAME}.sh"
sed -i "s/rabbitmq=[0-9]*/rabbitmq=${rabbitmq}/g" "$PROJECT_DIR/${PROJECT_NAME}.sh"
sed -i "s/portainer=[0-9]*/portainer=${portainer}/g" "$PROJECT_DIR/${PROJECT_NAME}.sh"

# 创建docker-compose文件
if [ ! -e "$PROJECT_DIR/docker-compose.yml" ]; then
    touch $PROJECT_DIR/docker-compose.yml
fi

# 加载 docker-compose的header配置
cat $PWD/common/base/header.yml > $PROJECT_DIR/docker-compose.yml

# 生成 mysql 容器配置
for ((i=1; i<=$mysql; i++)){
    sh $SERVICE_DIR/mysql/mysql.sh $i $SERVICE_DIR/mysql $PROJECT_NAME $PROJECT_DIR
}

# 生成 nginx 部分配置
for ((i=1; i<=$nginx; i++)){
    sh $SERVICE_DIR/nginx/nginx.sh $i $SERVICE_DIR/nginx $PROJECT_NAME $PROJECT_DIR
}

# 生成 nvm 部分配置
for ((i=1; i<=$nvm; i++)) {
    sh $SERVICE_DIR/nvm/nvm.sh $i $SERVICE_DIR/nvm $PROJECT_NAME $PROJECT_DIR
}

# 生成 redis 容器配置
for ((i=1; i<=$redis; i++)){
    sh $SERVICE_DIR/redis/redis.sh $i $SERVICE_DIR/redis $PROJECT_NAME $PROJECT_DIR
}

# 生成 后端api 容器配置
for ((i=1; i<=$marchsoft_api; i++)){
    sh $SERVICE_DIR/marchsoft-api/marchsoft-api.sh $i $SERVICE_DIR/marchsoft-api $PROJECT_NAME $PROJECT_DIR
}

# 生成 rabbitmq 容器配置
for ((i=1; i<=$rabbitmq; i++)){
    sh $SERVICE_DIR/rabbitmq/rabbitmq.sh $i $SERVICE_DIR/rabbitmq $PROJECT_NAME $PROJECT_DIR
}

# 生成 portainer 部分配置
for ((i=1; i<=$portainer; i++)){
    sh $SERVICE_DIR/portainer/portainer.sh $i $SERVICE_DIR/portainer $PROJECT_NAME $PROJECT_DIR
}

cat $PWD/common/base/footer.yml >> $PROJECT_DIR/docker-compose.yml

echo "构建脚本(build.sh)执行完成"

