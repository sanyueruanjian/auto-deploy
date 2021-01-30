#!/bin/bash
# 说明：
# 1) 在使用脚本前需要先装 docker 并好配置 docker 镜像加速
# 2) 构建的项目在 target 文件夹下以项目名（PROJECT_NAME）命名，构建完成后可以直接运行启动脚本(./compose.sh ↙)
# 3) 如果脚本中存在 '\r' 回车符原因不能执行，这里推荐下载 dos2unix 把当前下所有文件格式化为unix格式文件，
#    下载完软件后在下方取消注释可以对当前目录下的所有文件进行转换，

# ---- 构建 docker-compose.yml 用户需填的信息 -----------
# 项目名，这是必填项
PROJECT_NAME=marchsoft

# 设置构建容器的数量, 值为非负数, 如果不构建填：0
mysql=0
nginx=0
nvm=0
redis=0
marchsoft_api=0
rabbitmq=0
portainer=0


# ----- 操作前准备工作，格式转换、软件安装、创建目录... 以下用户无需更改 -----------------------------------------------------------------------------

# 脚本路径环境变量
PROJECT_DIR="$PWD/target/$PROJECT_NAME"
SERVICE_DIR="$PWD/service"
COMMON_DIR="$PWD/COMMON"

# 文件格式转换，将本文件夹下的dos格式文件转换为unix格式文件 #输出重定向到黑洞文件
#dos2unix `find . -type f` 2>/dev/null 1>&2 

# 判断是否进行构建，注意：\之后不能有空格，其转义的为回车符 \r
if [ "${mysql:-0}" -eq 0 ] && \
   [ "${nginx:-0}" -eq 0 ] && \
   [ "${nvm:-0}" -eq 0 ] && \
   [ "${redis:-0}" -eq 0 ] && \
   [ "${marchsoft_api:-0}" -eq 0 ] && \
   [ "${rabbitmq:-0}" -eq 0 ] && \
   [ "${portainer:-0}" -eq 0 ]; then
    echo "未构建任何容器，自动退出脚本"
    exit 1
fi

# 对文件夹进行处理，如果存在将之前的清空
if [ -e "$PROJECT_DIR" ]; then
    read -p "在'./target'下已存在项目 $PROJECT_NAME，是否清空 [y/n]: " res
    if [ "${res:-n}" = "y" ]; then
        rm -rf $PROJECT_DIR/*
        echo "已清空项目 $PROJECT_NAME(.target/$PROJECT_NAME) 重新生成"
        # 拷贝生成文件
        cat $PWD/compose/docker-compose.env > $PROJECT_DIR/.env
        cat $PWD/compose/compose.sh > $PROJECT_DIR/compose.sh
        # 添加执行权限
        chmod +x $PROJECT_DIR/compose.sh
    else
        echo "项目 $PROJECT_NAME 未清除(./target/$PROJECT_NAME)。容器的配置和环境变量未重新生成，运行时请确认一遍！"
    fi
else
    echo "初始化项目文件夹"
    mkdir -p $PROJECT_DIR
    # 拷贝生成文件
    cat $PWD/compose/docker-compose.env > $PROJECT_DIR/.env
    cat $PWD/compose/compose.sh > $PROJECT_DIR/compose.sh
    # 添加执行权限
    chmod +x $PROJECT_DIR/compose.sh
fi


# 打印系统已经使用的端口
if [ `which ss 2>/dev/null` ]; then
    echo "本机正在使用的端口号，请勿重复使用！"
    echo "-------------------------------------------------"
    ss -lntup -lntu|awk 'NR>1 {print $5}'|grep -Eo '[0-9]*$'|sort -gu|xargs -n 5|column -t
    echo "-------------------------------------------------"
elif [ `which netstat 2>/dev/null` ]; then
    echo "本机正在使用的端口号，请勿重复使用！"
    echo "-------------------------------------------------"
    netstat -lntup -lntu|awk 'NR>1 {print $4}'|grep -Eo '[0-9]*$'|sort -gu|xargs -n 5|column -t  
    echo "-------------------------------------------------"
fi
#--------------------------------------------------------------------------------------------------------------------------------------------------

# 修改启动项目shell脚本里的项目名
sed -i "s/PROJECT_NAME=.*/PROJECT_NAME=${PROJECT_NAME}/g" $PROJECT_DIR/compose.sh
# 修改启动项目shell脚本里的各个容器数量
sed -i "s/mysql=[0-9]*/mysql=${mysql}/g" $PROJECT_DIR/compose.sh
sed -i "s/nginx=[0-9]*/nginx=${nginx}/g" $PROJECT_DIR/compose.sh
sed -i "s/nvm=[0-9]*/nvm=${nvm}/g" $PROJECT_DIR/compose.sh
sed -i "s/redis=[0-9]*/redis=${redis}/g" $PROJECT_DIR/compose.sh
sed -i "s/marchsoft_api=[0-9]*/marchsoft_api=${marchsoft_api}/g" $PROJECT_DIR/compose.sh
sed -i "s/rabbitmq=[0-9]*/rabbitmq=${rabbitmq}/g" $PROJECT_DIR/compose.sh
sed -i "s/portainer=[0-9]*/portainer=${portainer}/g" $PROJECT_DIR/compose.sh

# 创建docker-compose文件
if [ ! -e "$PROJECT_DIR/docker-compose.yml" ]; then
    touch $PROJECT_DIR/docker-compose.yml
fi

# 加载 docker-compose的header配置
cat $PWD/compose/header-config.yml > $PROJECT_DIR/docker-compose.yml

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

cat $PWD/compose/footer-config.yml >> $PROJECT_DIR/docker-compose.yml

echo "构建脚本 (build.sh) 执行完成"