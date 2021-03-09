#!/bin/bash
# 说明：
# 1) 在使用脚本前需要先装 docker 并好配置 docker 镜像加速
# 2) 构建的项目在 target 文件夹下以项目名（PROJECT_NAME）命名，构建完成后可以直接运行启动脚本(./compose.sh ↙)
# 3) 如果脚本中存在 '\r' 回车符原因不能执行，这里推荐下载 dos2unix 把当前下所有文件格式化为unix格式文件，
#    下载完软件后在下方取消注释可以对当前目录下的所有文件进行转换，

# ---- 构建 docker-compose.yml 用户需填的信息 -----------
# 项目名，这是必填项
PROJECT_NAME=`awk -F "=" '/project_name/{print $2}' config-list.env`
# 部署项目所需的所有文件放置处（部署文件以及项目文件）
DEPLOY_PATH=`awk -F "=" '/deploy_path/{print $2}' config-list.env`


# 设置构建容器的数量, 值为非负数, 如果不构建填：0
mysql=`awk -F "=" '/mysql_count/{print $2}' config-list.env`
nginx=`awk -F "=" '/nginx_count/{print $2}' config-list.env`
nvm=`awk -F "=" '/nvm_count/{print $2}' config-list.env`
redis=`awk -F "=" '/redis_count/{print $2}' config-list.env`
marchsoft_api=`awk -F "=" '/marchsoft_api_count/{print $2}' config-list.env`
rabbitmq=`awk -F "=" '/rabbitmq_count/{print $2}' config-list.env`
portainer=`awk -F "=" '/portainer_count/{print $2}' config-list.env`;

# -m:mysql -n:nginx -v：nvm -r：redis -i:marchsoft_api -b:rabbitmq -p:portainer -h:帮助文档
while getopts 'm:n:v:r:i:b:p:h' OPT; do
    if [[ $OPT != "h" ]] && [[ ! $OPTARG =~ ^[0-9]+$ ]]; then 
        echo "=====参数错误====="
        exit 1;
    fi   
    case $OPT in
        m) mysql=$OPTARG;;
        n) nginx=$OPTARG;;
        v) nvm=$OPTARG;;
        i) marchsoft_api=$OPTARG;;
        r) redis=$OPTARG;;
        b) rabbitmq=$OPTARG;;
        p) portainer=$OPTARG;;
        h) help
            exit 1;;
        ?) help
            exit 1;;
    esac 
done

#使用说明，用来提示输入参数X
help() {
  echo "
    # 表示容器的参数:参数对应容器 容器说明[容器默认数量]
    -m:mysql 数据库容器[1] 
    -n:nginx 代理容器[1] 
    -v:nvm 前端容器[1] 
    -i:marchsoft_api 后端容器[1] 
    -b:rabbitmq 消息中间件容器[1] 
    -p:portainer 容器可视化容器[0] 
    -h:命令文档"
  exit 1
}

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
    rm -rf $PROJECT_DIR/*
    echo "已清空项目 $PROJECT_NAME(.target/$PROJECT_NAME) 重新生成"
    # 拷贝生成文件
    cat $PWD/compose/docker-compose.env > $PROJECT_DIR/.env
    sed -i "s/GLOBAL_PATH=.*/GLOBAL_PATH=\\${DEPLOY_PATH}\/${PROJECT_NAME}/g" $PROJECT_DIR/.env
    cat $PWD/compose/compose.sh > $PROJECT_DIR/compose.sh
    # 添加执行权限
    chmod +x $PROJECT_DIR/compose.sh
else
    echo "初始化项目文件夹"
    mkdir -p $PROJECT_DIR
    # 拷贝生成文件
    cat $PWD/compose/docker-compose.env > $PROJECT_DIR/.env
    sed -i "s/GLOBAL_PATH=.*/GLOBAL_PATH=\\${DEPLOY_PATH}\/${PROJECT_NAME}/g" $PROJECT_DIR/.env
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
    local port=`awk -F "=" '/mysql$i_port/{print $2}' config-list.env`
    sh $SERVICE_DIR/mysql/mysql.sh $i $SERVICE_DIR/mysql $PROJECT_NAME $PROJECT_DIR $port 
}

# 生成 nginx 部分配置
for ((i=1; i<=$nginx; i++)){
    local port=`awk -F "=" '/nginx$i_port/{print $2}' config-list.env`
    sh $SERVICE_DIR/nginx/nginx.sh $i $SERVICE_DIR/nginx $PROJECT_NAME $PROJECT_DIR $port
}

# 生成 nvm 部分配置
for ((i=1; i<=$nvm; i++)) {
    sh $SERVICE_DIR/nvm/nvm.sh $i $SERVICE_DIR/nvm $PROJECT_NAME $PROJECT_DIR
}

# 生成 redis 容器配置
for ((i=1; i<=$redis; i++)){
    local port=`awk -F "=" '/redis$i_port/{print $2}' config-list.env`
    sh $SERVICE_DIR/redis/redis.sh $i $SERVICE_DIR/redis $PROJECT_NAME $PROJECT_DIR $port
}

# 生成 后端api 容器配置
for ((i=1; i<=$marchsoft_api; i++)){
    sh $SERVICE_DIR/marchsoft-api/marchsoft-api.sh $i $SERVICE_DIR/marchsoft-api $PROJECT_NAME $PROJECT_DIR
}

# 生成 rabbitmq 容器配置
for ((i=1; i<=$rabbitmq; i++)){
    local port=`awk -F "=" '/rabbtimq$i_port/{print $2}' config-list.env`
    sh $SERVICE_DIR/rabbitmq/rabbitmq.sh $i $SERVICE_DIR/rabbitmq $PROJECT_NAME $PROJECT_DIR $port
}

# 生成 portainer 部分配置
for ((i=1; i<=$portainer; i++)){
    local port=`awk -F "=" '/portainer$i_port/{print $2}' config-list.env`
    sh $SERVICE_DIR/portainer/portainer.sh $i $SERVICE_DIR/portainer $PROJECT_NAME $PROJECT_DIR $port
}

cat $PWD/compose/footer-config.yml >> $PROJECT_DIR/docker-compose.yml

echo "构建脚本 (build.sh) 执行完成"

# 生成docker证书
cd ./certs
chmod +x docker-cert-create.sh
bash docker-cert-create.sh
cd ../

# 开始构建容器并启动
cd ./target/$PROJECT_NAME
bash compose.sh
cd ../../

# 将项目拉取脚本复制到项目放置目录
cp ./obtain_project.sh $DEPLOY_PATH/$PROJECT_NAME/project
chmod +x $DEPLOY_PATH/$PROJECT_NAME/project/obtain_project.sh

echo "环境搭建完成"

